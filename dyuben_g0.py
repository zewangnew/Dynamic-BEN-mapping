#!/usr/bin/python
import glob
import sys
import os
from shutil import copyfile
#for filename in glob.iglob(datapath+'/**/*.sh', recursive=True):
#    print(filename)
#!/usr/bin/env bash
def check_for_files(filepath):
    for filepath_object in glob.glob(filepath):
        if os.path.isfile(filepath_object):
            return True

    return False
scripts_dir="/data/hcp_analysis/scripts"
## change the output directory to your own
odir="/data/hcp_analysis/results_dyuben_sm"
if os.path.isdir(odir)==False:
    os.mkdir(odir)
# the compiled dynamic entropy mapping code
mvcmd=scripts_dir+"/gpudynmsubengap"

restdat_dirname="REST"

# the processed HCP data are in the MNI space with a resolution of 2x2x2 mm3
print(os.environ.get("FSLDIR"))
# a brain mask is used to reduce the computation burden
brainmask=scripts_dir+'/MNI152_T1_2mm_brain_mask.nii.gz'
print(brainmask)
sourcedatdir="/data/hcprest"
sublist=scripts_dir+"/subjectlist.txt"
print(sublist)
#sublist=${scripts_dir}/list1.txt
nsub=0
#datsubdir=MNINonLinear/Results
session=["rfMRI_REST2_LR", "rfMRI_REST2_RL", "rfMRI_REST1_LR", "rfMRI_REST1_RL"] 
listfi = open(sublist,"r")
for lyne in listfi:
    if lyne[0] == '#': 
        continue
    lyne=lyne.rstrip()  
    nsub=nsub+1 

    print (nsub)

    for r1 in session:
        datfile=sourcedatdir+"/"+lyne + "/MNINonLinear/Results/" +r1+"/s" +r1 + "_hp2000_clean.nii.gz"
        
        if not os.path.isfile(datfile):
            continue
        nmvfile=odir+"/dyuben"+lyne+ "_"+r1+".nii"
        nmvfilestr=odir+"/dyuben"+lyne+ "_"+r1+"*"
        
        mvfile=odir+"/dyuben"+lyne+ "_"+r1+".nii"  
        mvfilestr=odir+"/dyuben"+lyne+ "_"+r1+"*"
        if not check_for_files(mvfilestr):
            sdatfile=sourcedatdir+"/"+lyne + "/MNINonLinear/Results/" +r1+"/s" +r1 + "_hp2000_clean.nii.gz"
            print(sdatfile)
            # minor smoothing is used to suppress spatial noise. This is acutally not necessary for large data like HCP
            if not os.path.isfile(sdatfile):
               cmdstr="fslmaths "+datfile +" -kernel gauss 2.54 -fmean -mas " +brainmask +" " +sdatfile
               print (cmdstr)
               os.system(cmdstr)
            # parameters for call dynamic entropy mapping
            #  d -- window length for SampEn
            #  r -- cutoff threshold. meaning r*std
            #  s -- don't change the default value. It is used in a project not fully validated
            #  g -- ID of the GPU. If you only have one GPU, set it to be 0. If you have more and you want to use the n-th GPU, set g to be n-1
            #  c -- number of threads. Use 30 by default
            #  dwinlen -- length of the sliding window
            #  otype -- 0 means saving the thresholded entropy map only
            #  timeshift -- the gap between adjacent sliding window
            #  m -- brain mask file
            #  i --  input 4D images in nii or nii.gz format
            #  o -- prefix of the output
            cmdstr=mvcmd + " -d 3 -r 0.3 -s 1 -g 0 -c 30 -dwinlen 600 -otype 0 -timeshift 10 -m "+brainmask+ " -i  "+sdatfile+" -o "+mvfile
            print (cmdstr)
            print(nsub)
            os.system(cmdstr)
            #os.remove(datfile)
            #if not os.path.isfile(sdatfile)
            #    os.remove(sdatfile)

listfi.close()

