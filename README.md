# 10G/25G Ethernet Reference Designs for the Opsero Quad SFP28 FMC

## UNDER DEVELOPMENT

This project is currently under active development and may undergo significant changes.

## Description

This project demonstrates the use of the Opsero [Quad SFP28 FMC] with 10G/25G Ethernet SFP+/SFP28 modules
and it supports several FPGA/MPSoC development boards.

![Quad SFP28 FMC](https://ethernetfmc.com/images/quad-sfp28-fmc/quad-sfp28-fmc-top.png "Quad SFP28 FMC")

Important links:

* The user guide for these reference designs is hosted here: [10G/25G Ethernet for Quad SFP28 FMC docs](https://sfp28-xxv.ethernetfmc.com "10G/25G Ethernet for Quad SFP28 FMC docs")
* To report a bug: [Report an issue](https://github.com/fpgadeveloper/sfp28-fmc-xxv/issues "Report an issue").
* For technical support: [Contact Opsero](https://opsero.com/contact-us "Contact Opsero").
* To purchase the mezzanine card: [Quad SFP28 FMC order page](https://opsero.com/product/quad-sfp28-fmc "Quad SFP28 FMC order page").

## Requirements

This project is designed for version 2024.1 of the Xilinx tools (Vivado/Vitis/PetaLinux). 
If you are using an older version of the Xilinx tools, then refer to the 
[release tags](https://github.com/fpgadeveloper/sfp28-fmc-xxv/tags "releases")
to find the version of this repository that matches your version of the tools.

In order to test this design on hardware, you will need the following:

* Vivado 2024.1
* PetaLinux Tools 2024.1
* [Quad SFP28 FMC]
* One of the [supported evaluation boards](https://sfp28-xxv.ethernetfmc.com/en/latest/supported_carriers.html)
* [Xilinx Soft TEMAC license](https://ethernetfmc.com/getting-a-license-for-the-xilinx-tri-mode-ethernet-mac/ "Xilinx Soft TEMAC license")

## Target designs

This repo contains several designs that target various supported development boards and their
FMC connectors. The table below lists the target design name, the SFP28 ports supported by the design and 
the FMC connector on which to connect the Quad SFP28 FMC. Some of the target designs
require a license to generate a bitstream with the AMD Xilinx tools.

| Target board        | Target design     | SFP28 ports | FMC Slot    | License<br> required |
|---------------------|-------------------|-------------|-------------|-----|
| [KC705]             | `kc705_hpc`       | 4x          | HPC         | YES |
| [KCU105]            | `kcu105_hpc`      | 4x          | HPC         | YES |
| [UltraZed-EV carrier] | `uzev`          | 4x          | HPC         | NO  |
| [VC707]             | `vc707_hpc1`      | 4x          | HPC1        | YES |
| [VC707]             | `vc707_hpc2`      | 4x          | HPC2        | YES |
| [VC709]             | `vc709_hpc`       | 4x          | HPC         | YES |
| [VCK190]            | `vck190_fmcp1`    | 4x          | FMCP1       | YES |
| [VCK190]            | `vck190_fmcp2`    | 4x          | FMCP2       | YES |
| [VMK180]            | `vmk180_fmcp1`    | 4x          | FMCP1       | YES |
| [VMK180]            | `vmk180_fmcp2`    | 4x          | FMCP2       | YES |
| [VCU118]            | `vcu118`          | 4x          | FMCP        | YES |
| [ZC706]             | `zc706_hpc`       | 4x          | HPC         | YES |
| [ZCU102]            | `zcu102_hpc0`     | 4x          | HPC0        | YES |
| [ZCU102]            | `zcu102_hpc1`     | 4x          | HPC1        | YES |
| [ZCU106]            | `zcu106_hpc0`     | 4x          | HPC0        | NO  |
| [ZCU111]            | `zcu111`          | 4x          | FMCP        | YES |
| [ZCU208]            | `zcu208`          | 4x          | FMCP        | YES |

## Build instructions

Clone the repo:
```
git clone https://github.com/fpgadeveloper/sfp28-fmc-xxv.git
```

Source Vivado and PetaLinux tools:

```
source <path-to-petalinux>/2024.1/settings.sh
source <path-to-vivado>/2024.1/settings64.sh
```

Build all (Vivado project and PetaLinux):

```
cd sfp28-fmc-xxv/PetaLinux
make petalinux TARGET=zcu106_hpc0
```

More comprehensive build instructions can be found in the user guide:
* [For Windows users](https://sfp28-xxv.ethernetfmc.com/en/latest/build_instructions.html#windows-users)
* [For Linux users](https://sfp28-xxv.ethernetfmc.com/en/latest/build_instructions.html#linux-users)

## Contribute

We strongly encourage community contribution to these projects. Please make a pull request if you
would like to share your work:
* if you've spotted and fixed any issues
* if you've added designs for other target platforms

Thank you to everyone who supports us!

## About us

This project was developed by [Opsero Inc.](https://opsero.com "Opsero Inc."),
a tight-knit team of FPGA experts delivering FPGA products and design services to start-ups and tech companies. 
Follow our blog, [FPGA Developer](https://www.fpgadeveloper.com "FPGA Developer"), for news, tutorials and
updates on the awesome projects we work on.

[Quad SFP28 FMC]: https://ethernetfmc.com/docs/quad-sfp28-fmc/overview/
[KC705]: https://www.xilinx.com/kc705
[VC707]: https://www.xilinx.com/vc707
[VC709]: https://www.xilinx.com/vc709
[VCK190]: https://www.xilinx.com/vck190
[VMK180]: https://www.xilinx.com/vmk180
[VCU108]: https://www.xilinx.com/vcu108
[VCU118]: https://www.xilinx.com/vcu118
[KCU105]: https://www.xilinx.com/kcu105
[ZC706]: https://www.xilinx.com/zc706
[ZCU111]: https://www.xilinx.com/zcu111
[ZCU208]: https://www.xilinx.com/zcu208
[UltraZed-EV carrier]: https://www.xilinx.com/products/boards-and-kits/1-y3n9v1.html
[ZCU102]: https://www.xilinx.com/zcu102
[ZCU106]: https://www.xilinx.com/zcu106

