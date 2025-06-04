package main

import "fmt"

const (
	// INPOD marks/masks
	InpodTProxyMark      = 0x111
	InpodTProxyMask      = 0xfff
	InpodMark            = 1337 // this needs to match the inpod config mark in ztunnel.
	InpodMask            = 0xfff
	InpodRestoreMask     = 0xffffffff
	ChainInpodOutput     = "ISTIO_OUTPUT"
	ChainInpodPrerouting = "ISTIO_PRERT"
	ChainHostPostrouting = "ISTIO_POSTRT"
	RouteTableInbound    = 100

	DNSCapturePort              = 15053
	ZtunnelInboundPort          = 15008
	ZtunnelOutboundPort         = 15001
	ZtunnelInboundPlaintextPort = 15006
	ProbeIPSet                  = "istio-inpod-probes"
)

func main() {
	inpodMark := fmt.Sprintf("0x%x", InpodMark) + "/" + fmt.Sprintf("0x%x", InpodMask)
	inpodTproxyMark := fmt.Sprintf("0x%x", InpodTProxyMark) + "/" + fmt.Sprintf("0x%x", InpodTProxyMask)
	fmt.Printf("Inpod mark: %s\n", inpodMark)
	fmt.Printf("Inpod proxy mark: %s\n", inpodTproxyMark)
}
