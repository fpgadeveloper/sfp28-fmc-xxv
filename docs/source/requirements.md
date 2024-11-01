# Requirements

In order to test this design on hardware, you will need the following:

* Vivado 2024.1
* PetaLinux Tools 2024.1
* [Quad SFP28 FMC]
* [Xilinx 10G/25G Ethernet MAC/PCS (25GEMAC) License](https://www.xilinx.com/products/intellectual-property/ef-di-25gemac.html)
* One of the supported carrier boards listed below

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



[Quad SFP28 FMC]: https://ethernetfmc.com/docs/quad-sfp28-fmc/overview/
