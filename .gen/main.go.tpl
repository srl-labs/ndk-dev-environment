package main

import (
	"context"
	"os"
	"sync"
	"time"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"github.com/nokia/srlinux-ndk-go/v21/ndk"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/encoding/prototext"
)

const (
	appName       = "{{ getenv "APPNAME" }}"
	logTimeFormat = "2006-01-02 15:04:05 MST"
)

type Agent struct {
	Name  string // Agent name
	AppID uint32

	gRPCConn     *grpc.ClientConn
	logger       *zerolog.Logger
	retryTimeout time.Duration

	// NDK Service clients
	SDKMgrServiceClient       ndk.SdkMgrServiceClient
	NotificationServiceClient ndk.SdkNotificationServiceClient
	TelemetryServiceClient    ndk.SdkMgrTelemetryServiceClient
}

func main() {
	// set logger parameters
	logger := zerolog.New(zerolog.ConsoleWriter{
		Out:        os.Stderr,
		TimeFormat: logTimeFormat,
		NoColor:    true,
	}).With().Timestamp().Logger()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	ctx = metadata.AppendToOutgoingContext(ctx, "agent_name", appName)

	agent := newAgent(ctx, appName, &logger)

	wg := &sync.WaitGroup{}

	// Config notifications
	wg.Add(1)
	go func() {
		defer wg.Done()
		configChan := agent.StartConfigNotificationStream(ctx)
		for {
			select {
			case notif := <-configChan:
				b, err := prototext.MarshalOptions{Multiline: true, Indent: "  "}.Marshal(notif)
				if err != nil {
					log.Printf("Config notification Marshal failed: %+v", err)
					continue
				}

				agent.logger.Info().
					Msgf("Received notifications:\n%s", b)

			case <-ctx.Done():
				return
			}
		}
	}()

	wg.Wait()

	<-ctx.Done()
}

func newAgent(ctx context.Context, name string, logger *zerolog.Logger) *Agent {
	// create gRPC connection
	// https://learn.srlinux.dev/ndk/guide/dev/go/#establish-grpc-channel-with-ndk-manager-and-instantiate-an-ndk-client
	conn, err := grpc.Dial("localhost:50053", grpc.WithInsecure())
	if err != nil {
		log.Fatal().
			Err(err).
			Msg("gRPC connect failed")
	}

	// create SDK Manager Client
	sdkMgrClient := ndk.NewSdkMgrServiceClient(conn)
	// create Notification Service Client
	notifSvcClient := ndk.NewSdkNotificationServiceClient(conn)
	// create Telemetry Service Client
	telemetrySvcClient := ndk.NewSdkMgrTelemetryServiceClient(conn)

	// register agent
	// http://learn.srlinux.dev/ndk/guide/dev/go/#register-the-agent-with-the-ndk-manager
	r, err := sdkMgrClient.AgentRegister(ctx, &ndk.AgentRegistrationRequest{})
	if err != nil {
		log.Fatal().
			Err(err).
			Msg("Agent registration failed")
	}

	logger.Info().
		Uint32("app-id", r.GetAppId()).
		Str("name", name).
		Msg("Application registered successfully!")

	return &Agent{
		logger:                    logger,
		retryTimeout:              5 * time.Second,
		Name:                      name,
		AppID:                     r.GetAppId(),
		gRPCConn:                  conn,
		SDKMgrServiceClient:       sdkMgrClient,
		NotificationServiceClient: notifSvcClient,
		TelemetryServiceClient:    telemetrySvcClient,
	}
}
