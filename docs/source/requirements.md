# Requirements

In order to test this design on hardware, you will need the following:

* Vivado 2025.2
* One of the embedded Linux flows (both run on a Linux host only):
  * PetaLinux Tools 2025.2, or
  * Yocto (AMD EDF): Vitis 2025.2 (for `sdtgen`/`xsct`) and Google's `repo` tool — see [Yocto](yocto)
* [Quad SFP28 FMC]
* [Xilinx 10G/25G Ethernet MAC/PCS (25GEMAC) License](https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html)
  (see [Licenses](#licenses) below)
* One of the supported carrier boards listed below
* An SD card (the Linux images boot from SD card)
* SFP+/SFP28 modules or cables and a link partner (see [SFP modules and link partner](#sfp-modules-and-link-partner) below)

## Licenses

* **XXV Ethernet IP license.** The 10G/25G Ethernet Subsystem is a separately licensed IP core.
  Without a license that permits bitstream generation for it (license features
  `xxv_eth_mac_pcs` and `xxv_eth_basekr`), Vivado can create the project and run synthesis and
  implementation, but bitstream generation fails. A full license can be purchased from AMD, and a
  time-limited hardware evaluation license is available from the
  [AMD product page](https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html).
  All of the target designs require this license.
* **Vivado edition.** Some target boards require the Vivado Enterprise edition (a 30-day
  evaluation license is available from the AMD licensing site). The others can be built with the
  free Vivado Standard edition. The [build instructions](build_instructions.md#target-designs)
  list the edition required by each target.

When the XXV Ethernet IP is used under a license that includes evaluation features, Vivado
reports `CRITICAL WARNING: [Vivado 12-1790] Evaluation License Warning` during the build. This
warning does not stop the build. If you use an evaluation license, read the core's product
guide (PG210, linked from the
[AMD product page](https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html))
for the limitations of a design built with it.

## SFP modules and link partner

* **Rate.** Each target runs at one fixed line rate: 10G, or 25G for the targets with the `_25g`
  suffix. Use modules that support that rate: 10G SFP+ optics, 10G DAC cables or 10GBASE-T copper
  SFP+ modules for the 10G targets, and 25G SFP28 optics or DAC cables for the `_25g` targets. A
  25G-only SFP28 module is rejected by the 10G targets (see
  [Troubleshooting](troubleshooting.md#unsupported-sfp-module-no-common-interface-modes)).
* **Link partner.** Each SFP28 port is a separate network interface. To pass traffic, connect it
  to a 10G/25G network card in a PC, or to a switch port, running at the same fixed rate as the
  target with FEC and auto-negotiation turned off. See [Testing the SFP28 ports](testing).
* **Board Ethernet port (optional).** The carrier board's own Ethernet port (RJ45) is enabled in
  the Linux images. It is convenient for logging into the board over SSH while the SFP28 ports are
  under test.

## List of supported boards

{% set unique_boards = {} %}
{% for design in data.designs %}
	{% if design.publish %}
	    {% if design.board not in unique_boards %}
	        {% set _ = unique_boards.update({design.board: {"group": design.group, "link": design.link, "connectors": []}}) %}
	    {% endif %}
	    {% if design.connector not in unique_boards[design.board]["connectors"] %}
	    	{% set _ = unique_boards[design.board]["connectors"].append(design.connector) %}
	    {% endif %}
	{% endif %}
{% endfor %}

{% for group in data.groups %}
    {% set boards_in_group = [] %}
    {% for name, board in unique_boards.items() %}
        {% if board.group == group.label %}
            {% set _ = boards_in_group.append(board) %}
        {% endif %}
    {% endfor %}

    {% if boards_in_group | length > 0 %}
### {{ group.name }} boards

| Carrier board        | Supported FMC connector(s)    |
|---------------------|--------------|
{% for name,board in unique_boards.items() %}{% if board.group == group.label %}| [{{ name }}]({{ board.link }}) | {% for connector in board.connectors %}{{ connector }} {% endfor %} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

For list of the target designs showing the number of SFP28 ports supported, refer to the build instructions.



[Quad SFP28 FMC]: https://docs.opsero.com/op081/datasheet/overview/
