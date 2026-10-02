# Build instructions

## Source code

The source code for the reference designs is managed on this Github repository:

* [https://github.com/fpgadeveloper/sfp28-fmc-xxv](https://github.com/fpgadeveloper/sfp28-fmc-xxv)

To get the code, you can follow the link and use the **Download ZIP** option, or you can clone it
using this command:
```
git clone https://github.com/fpgadeveloper/sfp28-fmc-xxv.git
```

## License requirements

Some of the designs in this repository target dev boards for which a license is required to generate a bitstream. 
Others can be built with the Vivado ML Standard Edition **without a license**. The table of target designs in the 
following section contains a column specifying which designs require a license, and which can be built without a 
license.

Additionally, all of the designs in this repository use the 10G/25G Ethernet Subsystem (XXV
Ethernet) IP, which is licensed separately from the Vivado edition itself. The **IP License**
column in the tables below indicates the designs that require such a license to generate a
bitstream (all of them). Without the license, the `xsa` stage stops at bitstream generation with
an error such as:

```none
ERROR: [Common 17-69] Command failed: This design contains one or more cells for which bitstream generation is not permitted:
sfp_i/xxv_ethernet_0/inst/..._CORE (<encrypted cellview>)
```

and earlier in the log Vivado reports
`WARNING: [IP_Flow 19-650] IP license key 'xxv_eth_mac_pcs@2025.05' is enabled with a Design_Linking license.`
A time-limited hardware evaluation license is available from AMD for testing. See
[Licenses](requirements.md#licenses) for details, and
[Troubleshooting](troubleshooting.md#bitstream-generation-fails-with-common-17-69) if you install
a license after a failed build.


## Target designs

This repo contains several designs that target the various supported development boards and their
FMC connectors. The table below lists the target design name, the Ethernet ports supported by the design and 
the FMC connector on which to connect the mezzanine card.

{% for linkspeed in ["10","25"] %}
### {{ linkspeed }}G designs

These designs will support {{ linkspeed }}G SFP+/SFP28 modules.

| Target board        | Target design     | Ports   | FMC Slot    | Vivado<br> Edition | IP<br>License |
|---------------------|-------------------|---------|-------------|-----|-----|
{% for design in data.designs %}{% if design.linkspeed == linkspeed and design.publish %}| [{{ design.board }}]({{ design.link }}) | `{{ design.label }}` | {{ design.lanes | length }}x | {{ design.connector }} | {{ "Enterprise" if design.license else "Standard 🆓" }} | {{ "Required" if design.ip_license else "-" }} |
{% endif %}{% endfor %}
{% endfor %}

Notes:

1. The Vivado Edition column indicates which designs are supported by the Vivado *Standard* Edition, the
   FREE edition which can be used without a license. Vivado *Enterprise* Edition requires
   a license however a 30-day evaluation license is available from the AMD Xilinx Licensing site.

## Cross-platform build runner

All builds are driven by the `build.py` runner at the root of the repository,
on **both Windows and Linux** — the build instructions are the same for the
two operating systems. Each command builds whatever it depends on
automatically, skips anything that is already built, and locates the AMD
tools itself, so there is no need to source the settings scripts beforehand.

On Linux and on Windows (git bash), commands are run with the `build.sh`
shim, which finds a suitable Python 3 automatically (including the
interpreter bundled with the AMD tools). Windows users who prefer not to
use git bash can run the same commands from Command Prompt or PowerShell
using `build.bat` instead — the commands and arguments are otherwise
identical, for example `build.bat xsa --target <target>`.

To see the available targets and the state of a build:

```
./build.sh list                       # list the targets and their attributes
./build.sh status --target <target>   # show the per-stage artifact state
./build.sh clean --target <target>    # delete a target's generated outputs
```

```{note}
The embedded Linux images (PetaLinux and Yocto) can only be built on a
native Linux machine; everything else builds on Windows too. On Windows, the
runner refuses the Linux-only stages up front and prints the exact command
to run on the Linux machine. For Versal targets on Windows, the runner also
verifies that the project path fits within the 260-character Windows path
limit before building, and explains the `subst` workaround if it does not.
```

```{attention}
The legacy `make` interface described in previous versions of
this documentation still works on Linux — each Makefile is now a thin
wrapper around `build.sh` — but it is deprecated and will be removed at the
next version update.
```

### Build Vivado project

This single command creates the Vivado project, generates the bitstream and
exports the hardware to an XSA file:

```
./build.sh xsa --target <target>
```

Valid targets are:
{% for design in data.designs if design.publish %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endfor %}

If you want the Vivado project and block design without generating a
bitstream — for example, to explore or modify the design in the Vivado GUI —
run `./build.sh project --target <target>` instead, then open the project
from `Vivado/<target>/`.

### Build PetaLinux

The PetaLinux build requires a native Linux machine (one of the [supported
Linux distributions]) with PetaLinux Tools 2025.2 installed. The runner
locates and sources the PetaLinux `settings.sh` itself, and builds the
Vivado XSA first if it does not already exist:

```
./build.sh petalinux --target <target>
```

Valid targets for PetaLinux are:
{% for design in data.designs if design.petalinux and design.publish %} `{{ design.label }}`{{ ", " if not loop.last else "." }} {% endfor %}

The output products are written to `PetaLinux/<target>/images/linux/`.

#### PetaLinux offline build

If you need to build the PetaLinux projects offline (without an internet
connection), you can follow these instructions.

1. Download the sstate-cache artefacts from the Xilinx downloads site (the
   same page where you downloaded PetaLinux tools). There are four of them:
   * aarch64 sstate-cache (for ZynqMP designs)
   * arm sstate-cache (for Zynq designs)
   * microblaze sstate-cache (for Microblaze designs)
   * Downloads (for all designs)
2. Extract the contents of those files to a single location on your hard
   drive, for this example we'll say `/home/user/petalinux-sstate`. That
   should leave you with the following directory structure:
   ```
   /home/user/petalinux-sstate
                             +---  aarch64
                             +---  arm
                             +---  downloads
                             +---  microblaze
   ```
3. Create a text file called `offline.txt` in the `PetaLinux` directory of
   the project repository. The file should contain a single line of text
   specifying the path where you extracted the sstate-cache files. In this
   example, the contents of the file would be:
   ```
   /home/user/petalinux-sstate
   ```
   It is important that the file contain only one line and that the path is
   written with NO TRAILING FORWARD SLASH.

The PetaLinux builds will then be configured for offline build.

### Build Yocto

The Yocto (AMD EDF) build requires a native Linux machine with Vivado 2025.2 and Vitis 2025.2
installed, and Google's `repo` tool on the `PATH`. The runner sources the tool settings itself
and builds the Vivado XSA first if it does not already exist:

```
./build.sh yocto --target <target>
```

The output products are written to `Yocto/<target>/images/linux/`. See [Yocto](yocto) for the
requirements, the outputs and how to write the SD card.

### Standalone (baremetal)

This repository has no standalone (baremetal) application: the SFP28 ports are exercised from
Linux. The `standalone` stage of the build runner reports its steps as skipped for these
targets.

### Build everything

This builds everything that the target supports — the Vivado project and XSA,
the PetaLinux image and the Yocto image — and gathers the boot images into `bootimages/*.zip`:

```
./build.sh all --target <target>
./build.sh all --target all      # every target in the repo
```

On Windows, `all` builds everything that the host can build and reports the
Linux-only stages as `BLOCKED` rather than failing.

The boot-image zips are named `sfp28-fmc-xxv_<target>_petalinux-2025-2.zip` and
`sfp28-fmc-xxv_<target>_yocto-2025-2.zip`. Each one contains a `readme.txt` describing how to
put the files on the SD card. If you rebuild a target, `./build.sh package --target <target>`
rewrites any zip that is older than the newly built files.

A full PetaLinux or Yocto build takes a lot of disk space. To free space once a target is built,
`./build.sh clean --keep-boot --target <target>` deletes the intermediate build files but keeps
the XSA, the boot files, the images and the zips.

[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment
