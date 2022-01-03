package main

import (
	"context"
	"io"
	"time"

	"github.com/nokia/srlinux-ndk-go/v21/ndk"
)

func (a *Agent) StartConfigNotificationStream(ctx context.Context) chan *ndk.NotificationStreamResponse {
	streamID := a.createNotificationSubscription(ctx)

	a.logger.Info().
		Uint64("stream-id", streamID).
		Msg("Notification stream created")

	notificationRegisterRequest := &ndk.NotificationRegisterRequest{
		Op:       ndk.NotificationRegisterRequest_AddSubscription,
		StreamId: streamID,
		SubscriptionTypes: &ndk.NotificationRegisterRequest_Config{ // config
			Config: &ndk.ConfigSubscriptionRequest{},
		},
	}

	streamChan := make(chan *ndk.NotificationStreamResponse)
	go a.startNotificationStream(ctx, notificationRegisterRequest, streamChan)

	return streamChan
}

// createNotificationSubscription creates a subscription and return the Stream ID.
// Stream ID is used to register notifications for other services.
func (a *Agent) createNotificationSubscription(ctx context.Context) uint64 {
	retry := time.NewTicker(a.retryTimeout)

	for {
		// get subscription and streamID
		notificationResponse, err := a.SDKMgrServiceClient.NotificationRegister(ctx,
			&ndk.NotificationRegisterRequest{
				Op: ndk.NotificationRegisterRequest_Create,
			})
		if err != nil || notificationResponse.GetStatus() != ndk.SdkMgrStatus_kSdkMgrSuccess {
			a.logger.Printf("agent %q could not register for notifications: %v. Status: %s", a.Name, err, notificationResponse.GetStatus().String())
			a.logger.Printf("agent %q retrying in %s", a.Name, a.retryTimeout)

			<-retry.C // retry timer
			continue
		}

		return notificationResponse.GetStreamId()
	}
}

func (a *Agent) startNotificationStream(ctx context.Context, req *ndk.NotificationRegisterRequest,
	streamChan chan *ndk.NotificationStreamResponse) {

	a.logger.Info().
		Uint64("stream-id", req.GetStreamId()).
		Str("subscription-type", subscriptionTypeName(req)).
		Msg("Starting streaming notifications")
	defer close(streamChan)

	retry := time.NewTicker(a.retryTimeout)
	stream := a.getNotificationStreamClient(ctx, req)

	for {
		select {
		case <-ctx.Done():
			return
		default:
			ev, err := stream.Recv()
			if err == io.EOF {
				a.logger.Printf("agent %s received EOF for stream %v", a.Name, req.GetSubscriptionTypes())
				a.logger.Printf("agent %s retrying in %s", a.Name, a.retryTimeout)

				<-retry.C // retry timer
				continue
			}
			if err != nil {
				a.logger.Printf("agent %s failed to receive notification: %v", a.Name, err)

				<-retry.C // retry timer
				continue
			}
			streamChan <- ev
		}
	}

}

// subscriptionTypeName returns the name of the enclosed subscription type
func subscriptionTypeName(r *ndk.NotificationRegisterRequest) string {
	var sType string
	switch r.GetSubscriptionTypes().(type) {
	case *ndk.NotificationRegisterRequest_Config:
		sType = "config"
	case *ndk.NotificationRegisterRequest_Appid:
		sType = "app id"
	case *ndk.NotificationRegisterRequest_Route:
		sType = "route"
	case *ndk.NotificationRegisterRequest_BfdSession:
		sType = "bfd"
	case *ndk.NotificationRegisterRequest_Intf:
		sType = "interface"
	case *ndk.NotificationRegisterRequest_LldpNeighbor:
		sType = "lldp"
	case *ndk.NotificationRegisterRequest_Nhg:
		sType = "next-hop group"
	case *ndk.NotificationRegisterRequest_NwInst:
		sType = "network instance"
	}

	return sType
}

// getNotificationStreamClient acquires the notification stream client that is used to receive
// streamed notifications
func (a *Agent) getNotificationStreamClient(
	ctx context.Context,
	req *ndk.NotificationRegisterRequest) ndk.SdkNotificationService_NotificationStreamClient {

	retry := time.NewTicker(a.retryTimeout)

	var streamClient ndk.SdkNotificationService_NotificationStreamClient
	for {
		registerResponse, err := a.SDKMgrServiceClient.NotificationRegister(ctx, req)
		if err != nil || registerResponse.GetStatus() != ndk.SdkMgrStatus_kSdkMgrSuccess {
			a.logger.Printf("agent %s failed registering to notification with req=%+v: %v", a.Name, req, err)
			a.logger.Printf("agent %s retrying in %s", a.Name, a.retryTimeout)

			<-retry.C // retry timer
			continue

		}

		streamClient, err = a.NotificationServiceClient.NotificationStream(ctx,
			&ndk.NotificationStreamRequest{
				StreamId: req.GetStreamId(),
			})
		if err != nil {
			a.logger.Printf("agent %s failed creating stream client with req=%+v: %v", a.Name, req, err)
			a.logger.Printf("agent %s retrying in %s", a.Name, a.retryTimeout)
			time.Sleep(a.retryTimeout)

			<-retry.C // retry timer
			continue
		}

		return streamClient
	}
}
