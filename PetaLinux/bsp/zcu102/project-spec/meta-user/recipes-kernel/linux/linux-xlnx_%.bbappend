FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"

# Patch xilinx_axienet driver to pulse an optional GPIO connected to the
# XXV's qpllreset_in_0 inside axienet_device_reset(), so the GTH QPLL
# re-locks after the Si5328 refclk has been programmed. Driven by the
# "qpllreset-gpios" property on every xxv_ethernet_* node in
# port-config.dtsi.
SRC_URI:append = " file://0001-xxv-qpllreset-gpio.patch"
