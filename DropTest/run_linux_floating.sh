#!/bin/bash 

# Check if coefh parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <coefh_value>"
    echo "Example: $0 1.25"
    exit 1
fi

COEFH=$1

fail () { 
    echo "Execution aborted."
    exit 1
}

# "name" and "dirout" are named according to the testcase
export name=deviceFloat
export dirout=${name}_out_coefh_${COEFH}
export diroutdata=${dirout}/data

# Create temporary XML with modified coefh - using unique name
export tmp_xml=${name}_Def_coefh_${COEFH}.xml
cp ${name}_Def.xml ${tmp_xml}
sed -i "s/<coefh value=\"[0-9.]*\"/<coefh value=\"${COEFH}\"/" ${tmp_xml}

# "executables" are renamed and called from their directory
export dirbin=../../DualSPHysics_v5.2/bin/linux
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${dirbin}
export gencase="${dirbin}/GenCase_linux64"
export dualsphysicscpu="${dirbin}/DualSPHysics5.2CPU_linux64"
export dualsphysicsgpu="${dirbin}/DualSPHysics5.2_linux64"
export boundaryvtk="${dirbin}/BoundaryVTK_linux64"
export partvtk="${dirbin}/PartVTK_linux64"
export partvtkout="${dirbin}/PartVTKOut_linux64"
export measuretool="${dirbin}/MeasureTool_linux64"
export computeforces="${dirbin}/ComputeForces_linux64"
export isosurface="${dirbin}/IsoSurface_linux64"
export flowtool="${dirbin}/FlowTool_linux64"
export floatinginfo="${dirbin}/FloatingInfo_linux64"
export tracerparts="${dirbin}/TracerParts_linux64"

# First do option 1 - Delete and run simulation
if [ -e ${dirout} ]; then 
    rm -r ${dirout}
fi

# Create output directories
mkdir -p ${dirout}
mkdir -p ${diroutdata}

# CODES are executed according the selected parameters of execution in this testcase
${gencase} ${tmp_xml%.*} ${dirout}/${name} -save:all
if [ $? -ne 0 ] ; then fail; fi

# Save the XML file in the output directory for reference
mv ${tmp_xml} ${dirout}/

${dualsphysicsgpu} -gpu ${dirout}/${name} ${dirout} -dirdataout data -svres
if [ $? -ne 0 ] ; then fail; fi

# Then do option 2 - Post-processing
export dirout2=${dirout}/particles
mkdir -p ${dirout2}
${partvtk} -dirin ${diroutdata} -savevtk ${dirout2}/PartFLuid -onlytype:-all,+fluid
if [ $? -ne 0 ] ; then fail; fi

${partvtk} -dirin ${diroutdata} -savevtk ${dirout2}/PartWavemaker -onlytype:-all,+moving
if [ $? -ne 0 ] ; then fail; fi

${partvtk} -dirin ${diroutdata} -savevtk ${dirout2}/PartFlap -onlytype:-all,+floating
if [ $? -ne 0 ] ; then fail; fi

${partvtkout} -dirin ${diroutdata} -savevtk ${dirout2}/PartFluidOut -SaveResume ${dirout2}/_ResumeFluidOut
if [ $? -ne 0 ] ; then fail; fi

export dirout2=${dirout}/boundary
mkdir -p ${dirout2}
${boundaryvtk} -loadvtk AutoActual -motiondata ${diroutdata} -savevtkdata ${dirout2}/Piston -onlytype:moving -savevtkdata ${dirout2}/OWSC -onlytype:floating -savevtkdata ${dirout2}/Tank.vtk -onlytype:fixed
if [ $? -ne 0 ] ; then fail; fi

export dirout2=${dirout}/surface
mkdir -p ${dirout2}
${isosurface} -dirin ${diroutdata} -saveiso ${dirout2}/Surface 
if [ $? -ne 0 ] ; then fail; fi

export dirout2=${dirout}/floatinginfo
mkdir -p ${dirout2}
${floatinginfo} -dirin ${diroutdata} -onlymk:15 -savedata ${dirout2}/FlapMotion 
if [ $? -ne 0 ] ; then fail; fi

export dirout2=${dirout}/forces
mkdir -p ${dirout2}
${computeforces} -dirin ${diroutdata} -savecsv ${dirout2}/_TankM0 -onlymk:10 -momentaxis:0:0.1:0.0:0:-0.1:0.0
if [ $? -ne 0 ] ; then fail; fi

echo "All done - Simulation completed with coefh = ${COEFH}"
