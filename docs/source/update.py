'''
Opsero Electronic Design Inc.

data.json is intended to be a centralized source of information regarding all of the target
designs and it ensures that the documentation and makefiles are consistent.
When data.json is updated with new information, this Python script can be run to update
the main README.md file of the repo, the makefiles and the .gitignore. We typically
use this script when adding/removing target designs.

The Sphinx documentation also refers to the data.json file when compiling the target design
and supported board tables.
'''

import os
import json

# Load the JSON data
def load_json():
    with open('data.json') as f:
        return json.load(f)

# Create design tables for the README.md file
# This function determines the formatting of the design tables
def create_tables(data):
    tables = []
    links = {}
    for linkspeed in ['10','25']:
        tables.append('### {}G designs'.format(linkspeed))
        tables.append('')
        tables.append('| Target board          | Target design      | Link speeds <br> supported | SFP28 ports | FMC Slot    | License<br> required |')
        tables.append('|-----------------------|--------------------|------------|-------------|-------------|-------|')
        for design in data['designs']:
            if design['publish'] == 'NO':
                continue
            if design['linkspeed'] == linkspeed:
                col1 = '[{0}]'.format(design['board']).ljust(21)
                col2 = '`{0}`'.format(design['label']).ljust(18)
                col3 = '{0}G'.format(design['linkspeed']).ljust(10)
                ports = '{}x'.format(len(design['lanes']))
                col4 = '{0}'.format(ports).ljust(11)
                col5 = '{0}'.format(design['connector']).ljust(11)
                col6 = '{0}'.format(design['license']).ljust(5)
                tables.append('| {0} | {1} | {2} | {3} | {4} | {5} |'.format(col1,col2,col3,col4,col5,col6))
                links[design['board']] = design['link']
        tables.append('')
    # Add the board links
    for k,v in links.items():
        tables.append('[{0}]: {1}'.format(k,v))
    return(tables)

# Update the README.md file target design tables
def update_readme(file_path,data):
    # Read the content of the file
    with open(file_path, 'r') as infile:
        lines = infile.readlines()

    # Open the same file in write mode to overwrite it
    with open(file_path, 'w') as outfile:
        inside_updater = False

        for line in lines:
            if '<!-- updater start -->' in line:
                # Write the start tag to the file
                outfile.write(line)
                # Write the tables
                tables = create_tables(data)
                for l in tables:
                    outfile.write("{}\n".format(l))
                inside_updater = True
            elif '<!-- updater end -->' in line:
                # Write the end tag to the file
                outfile.write(line)
                inside_updater = False
            elif not inside_updater:
                # Write the line if not inside the updater block
                outfile.write(line)

def get_root_targets(data):
    templates = {'fpga': 'microblaze', 'z7': 'zynq', 'zu': 'zynqMP', 'versal': 'versal'}
    targets = []
    for linkspeed in ['10','25']:
        targets.append('# {}G designs'.format(linkspeed))
        for design in data['designs']:
            if design['linkspeed'] != linkspeed:
                continue
            template = templates[design['group']]
            if design['petalinux'] == "YES":
                sw = 'both'
            else:
                sw = 'baremetal_only'
            target = '{}_target := {} {}'.format(design['label'],template,sw)
            targets.append(target)
    return(targets)

def get_vivado_targets(data):
    targets = ['{}_target := 0'.format(design['label']) for design in data['designs']]
    return(targets)

def get_vivado_build_targets(data):
    templates = {'fpga': 'mb', 'z7': 'zynq', 'zu': 'zynqmp', 'versal': 'versal'}
    targets = []
    for linkspeed in ['10','25']:
        targets.append('# {}G designs'.format(linkspeed))
        for design in data['designs']:
            if design['linkspeed'] != linkspeed:
                continue
            template = templates[design['group']]
            lanes = '{'
            for lane in design['lanes']:
                lanes += ' ' + lane
            lanes += ' }'
            target = 'dict set target_dict {} {{ {} {} {} {} "{}" }}'.format(design['label'],design['url'],design['boardname'],
                template,lanes,design['linkspeed'])
            targets.append(target)
    return(targets)

def get_petalinux_targets(data):
    templates = {'fpga': 'microblaze', 'z7': 'zynq', 'zu': 'zynqMP', 'versal': 'versal'}
    targets = []
    for linkspeed in ['10','25']:
        targets.append('# {}G designs'.format(linkspeed))
        for design in data['designs']:
            if design['linkspeed'] != linkspeed:
                continue
            if design['petalinux'] == 'NO':
                continue
            '''
            lanecfg = 'ports-'
            for lane in design['lanes']:
                lanecfg += lane
            '''
            lanecfg = 'ports-0123'
            template = templates[design['group']]
            target = '{}_target := {} {} {} {}'.format(design['label'],template,design['flashsize'],design['flashintf'],lanecfg)
            targets.append(target)
    return(targets)

def get_vitis_targets(data):
    templates = {'fpga': 'microblaze', 'z7': 'zynq', 'zu': 'zynqMP', 'versal': 'versal'}
    targets = []
    for design in data['designs']:
        if design['baremetal'] == 'NO':
            continue
        template = templates[design['group']]
        target = '{}_target := {}'.format(design['label'],template)
        targets.append(target)
    return(targets)

def get_ignore_paths(data):
    paths = []
    for design in data['designs']:
        p = 'Vivado/{}/'.format(design['label'])
        paths.append(p)
        p = 'PetaLinux/{}/'.format(design['label'])
        paths.append(p)
    return(paths)



# Update a file that uses "# UPDATER START" and "# UPDATER END" tags
def update_file(file_path,targets):
    # Read the content of the file
    with open(file_path, 'r') as infile:
        lines = infile.readlines()

    # Open the same file in write mode to overwrite it
    with open(file_path, 'w') as outfile:
        inside_updater = False

        for line in lines:
            if '# UPDATER START' in line:
                # Write the start tag to the file
                outfile.write(line)
                # Write the targets
                for l in targets:
                    outfile.write("{}\n".format(l))
                inside_updater = True
            elif '# UPDATER END' in line:
                # Write the end tag to the file
                outfile.write(line)
                inside_updater = False
            elif not inside_updater:
                # Write the line if not inside the updater block
                outfile.write(line)

# Make sure that there is a constraints file for all target designs
def check_constraints(data):
    for design in data['designs']:
        filename = '../../Vivado/src/constraints/{}.xdc'.format(design['label'])
        if not os.path.isfile(filename):
            print('WARNING: No constraints file found for target',design['label'])

# Read the JSON data
data = load_json()
file_path = '../../README.md'

# Update the main README.md file
update_readme(file_path,data)

# Update the root makefile
root_makefile = '../../Makefile'
root_targets = get_root_targets(data)
update_file(root_makefile,root_targets)

# Update the Vivado makefile
vivado_makefile = '../../Vivado/Makefile'
vivado_targets = get_vivado_targets(data)
update_file(vivado_makefile,vivado_targets)

# Update the Vivado build.tcl
vivado_build_tcl = '../../Vivado/scripts/build.tcl'
vivado_build_targets = get_vivado_build_targets(data)
update_file(vivado_build_tcl,vivado_build_targets)

## Update the Vitis makefile
#vitis_makefile = '../../Vitis/Makefile'
#vitis_targets = get_vitis_targets(data)
#update_file(vitis_makefile,vitis_targets)

# Update the PetaLinux makefile
petalinux_makefile = '../../PetaLinux/Makefile'
petalinux_targets = get_petalinux_targets(data)
update_file(petalinux_makefile,petalinux_targets)

# Update the gitignore
gitignore = '../../.gitignore'
gitignore_paths = get_ignore_paths(data)
update_file(gitignore,gitignore_paths)

# Check constraints
check_constraints(data)
