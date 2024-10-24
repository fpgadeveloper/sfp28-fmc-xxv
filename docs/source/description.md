# Description

In this reference design, each port of the [Quad SFP28 FMC] is connected to an [10G/25G Ethernet Subsystem IP]
which is connected to the system memory via an AXI DMA IP. 

## Block diagrams

The repository contains designs for both Zynq
UltraScale+ platforms and Versal platforms. The block diagrams for the designs are shown below:

### Zynq UltraScale+ designs

![ZynqMP XXV Ethernet design block diagram](images/zynqmp-xxv-eth-block-diagram.png)

### Versal designs

![Versal XXV Ethernet design block diagram](images/versal-xxv-eth-block-diagram.png)

## Supported Hardware Platforms

The hardware designs provided in this reference are based on Vivado and support a range of FPGA, MPSoC and ACAP evaluation
boards. The repository contains all necessary scripts and code to build these designs for the supported platforms listed below:

{% set unique_boards = {} %}
{% for design in data.designs %}
    {% if design.publish == "YES" %}
        {% if design.board not in unique_boards %}
            {% set _ = unique_boards.update({design.board: {"group": design.group, "link": design.link, "connectors": [], "speeds": []}}) %}
        {% endif %}
        {% if design.connector not in unique_boards[design.board]["connectors"] %}
            {% set _ = unique_boards[design.board]["connectors"].append(design.connector) %}
        {% endif %}
        {% if design.linkspeed not in unique_boards[design.board]["speeds"] %}
            {% set _ = unique_boards[design.board]["speeds"].append(design.linkspeed) %}
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

| Carrier board    | Supported FMC connector(s) | 10G support | 25G support |
|------------------|----------------------------|-------------|-------------|
{% for name,board in unique_boards.items() %}{% if board.group == group.label %}| [{{ name }}]({{ board.link }}) | {% for connector in board.connectors %}{{ connector }} {% endfor %} | {% if "10" in board.speeds %} ✅ {% else %} Not supported {% endif %} | {% if "25" in board.speeds %} ✅ {% else %} Not supported {% endif %} |
{% endif %}{% endfor %}
{% endif %}
{% endfor %}

Note that some of the hardware platforms cannot support 25G link speeds due to the limitations of the 
gigabit transceivers of the devices on those platforms.

## Supported Software

These reference designs can be driven within a PetaLinux environment. 
The repository includes all necessary scripts and code to build the PetaLinux environments. The table 
below outlines the corresponding applications available in each environment:

| Environment      | Available Applications  |
|------------------|-------------------------|
| PetaLinux        | Built-in Linux commands<br>Additional tools: ethtool, phytool, iperf3 |

[Quad SFP28 FMC]: https://ethernetfmc.com/docs/quad-sfp28-fmc/overview/
[10G/25G Ethernet Subsystem IP]: https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html