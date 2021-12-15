package main

import (
	"context"
	"os"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"

	"github.com/nokia/srlinux-ndk-go/ndk"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

const (
	appName       = "{{ getenv "APPNAME" }}"
	logTimeFormat = "2006-01-02 15:04:05 MST"
)

func main() {

	zerolog.TimeFieldFormat = logTimeFormat
	log.Logger = log.Output(zerolog.ConsoleWriter{
		Out:        os.Stderr,
		TimeFormat: logTimeFormat,
		NoColor:    true,
	})

	conn, err := grpc.Dial("localhost:50053", grpc.WithInsecure())
	if err != nil {
		log.Fatal().
			Err(err).
			Msg("gRPC connect failed")
	}
	defer conn.Close()

	sdkMgrClient := ndk.NewSdkMgrServiceClient(conn)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	// appending agent's name to the context metadata
	ctx = metadata.AppendToOutgoingContext(ctx, "agent_name", appName)

	r, err := sdkMgrClient.AgentRegister(ctx, &ndk.AgentRegistrationRequest{})
	if err != nil {
		log.Fatal().
			Err(err).
			Msg("agent registration failed")
	}

	log.Debug().
		Uint32("app-id", r.GetAppId()).
		Str("name", appName).
		Msg("app registered successfully!")
		
	<- ctx.Done()
}
