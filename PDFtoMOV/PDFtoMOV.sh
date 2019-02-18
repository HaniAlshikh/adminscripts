#!/bin/bash
#
# Converts a PDF with multiple pages to a movie
#
# the cURL command for any file can be obtained from Google Chrome using the copy as cURL function
# small google search can explain everything
#
# written by Carsten Sch�lzki edited by Hani Alshikh

# basic functions
msg_status() {
	echo -e "\033[0;32m$1\033[0m"
}
msg_error() {
	echo -e "\033[0;31m$1\033[0m"
}
msg_bold() {
	echo -e "\033[1;34m$1\033[0m"
}

download_file() {
    # EDITME
    curl 'https://docs.google.com/presentation/d/1_UDwOIGf_B8yfEKFlO8klrMvJrzxvlzFvaRSiAF01xE/export/pdf?id=1_UDwOIGf_B8yfEKFlO8klrMvJrzxvlzFvaRSiAF01xE&pageid=g43e7861bfd_0_17' -H 'authority: docs.google.com' -H 'upgrade-insecure-requests: 1' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.109 Safari/537.36' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'x-chrome-connected: id=112133096701946532173,mode=0,enable_account_consistency=false' -H 'x-client-data: CKu1yQEIhLbJAQiktskBCMS2yQEIqZ3KAQioo8oBCLGnygEIv6fKAQjkqMoBGPmlygE=' -H 'referer: https://docs.google.com/presentation/d/1_UDwOIGf_B8yfEKFlO8klrMvJrzxvlzFvaRSiAF01xE/edit' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' -H 'cookie: S=apps-presentations=kSi0RH1h8LCM7jFbeaxibmWPwnAxgLmK; CONSENT=YES+DE.en+20151011-09-0; HSID=Ahm6mZ2m_Rb9MubVl; SSID=A8sN216qM8emYJ9-T; APISID=W2DkalPANYGIWec2/A1WynQkYld8tHhiAj; SAPISID=o6l6uN2Gux1ERtHY/AP8XTa5056NNf_hHK; ANID=AHWqTUk5gFRv8SaExMu8Xv7YYlfonb13wRHX7qox_G6i8yIv5cMxGlnl2WQYK500; SID=EwfAE-zBa0fKXMxMFPQAUBGkVFTospXq6vb5d6Pd2sUF0ssMEEAJHVnx-TgbgwdzcGEKFg.; NID=160=VzF1L5m2k3MaqCDhCDoFOVLIIvmuHyicBNPKBcDjLyJmVX2zmJ4IXmBeqOHn53hVz_pZkY-pG1gg-mbpawIMrAm6cwCxVAfxREBr7IkhWSSBOQXKV5Vpjej_u49MKTmx9Jy35yCFDS5pT0LCUIgIgr67P0CuWIlcvGPiLA3wHX7b5hUqK50jeiUmiPQou-5C8uSj7dTf9u2aHLrC7d-sI7zT-tZ6KjMP3gOtyXNYJr4Cjif3cvtaD02iX_Vn1soG5G7L1foizlvtl4bktgU9aXjS_GXSJcDTxQ; S=explorer=7E8ABHzEXzVNm4cpr9110TGzKr5xr8c5; 1P_JAR=2019-2-17-18; SIDCC=AN0-TYsIIt78G9eUsH5U6WNd0e6XbQf5Uyy4cguSXPq4QeDN889HSaA6xi8EHO--pAvPUd0JK94' --compressed > figo.pdf    
    if ! [[ $? -eq "0" ]]; then
        msg_error "\n  faild to download\n"
        exit 1
    fi
}

usage() {
	cat <<EOF
    
$(msg_bold "Usage:")

please put the pdf file in the same directory as the script or point to it as an argument
$(basename "$0") <yourfile.pdf> output.mov

$(msg_bold "Description:")

this script converts a given PDF file to multiple PNGs and makes a video out of them.
everything happens in the same directory as the script.

$(msg_bold "Optional:")

this Script can also utilize a cURL to download the PDF and convert it, which make the whole process fully automated
just replace the EDITME part with your cURL 

$(msg_bold "Requirements:")

imagemagick https://www.imagemagick.org/
ffmpeg https://ffmpeg.org/ with the Dependencies

EOF
}

# processing
## 0. Check if input is ok and modify the variables if given
case $1 in
 -h|h|help|--help) usage 
     exit 0
     ;; 
esac

file=$1
file_count=$(ls *.pdf 2>/dev/null | wc -l)
output_name="KitchenMovie"

# check if there is a pdf file given from the user
if [[ $1 != *.pdf ]]; then
    # check if the first argument is not empty (if the user entered the output file name for example)
    if [[ $1 != '' ]]; then
        output_name=$1
    fi
    # check if the file already exist in the working directory
    if [[ $file_count -eq 1 ]]; then
        file=$(ls *.pdf)
    # try to download the file in case of automated use
    else
        [[ $file_count -gt 1 ]] && msg_status "\nmore than one PDF file was found. Attempting to download the one and only... "
        msg_status "\n> downloading the presentation \n"
        download_file
        file=figo.pdf
    fi
fi

if [[ $2 != '' ]]; then
    output_name=$2
fi

## 1. PDF to PNG's
msg_status "\n> processing $file... \n"
if ! [[ -d processing ]] ; then
    echo "  making a tmp folder..."
    mkdir processing 
fi

echo "  converting the PDF to PNGs..."
# check if the converting already happened to save time
generated_pngs=$(ls processing/ | wc -l | sed 's/ //g')
pdf_pages=$(mdls -n kMDItemNumberOfPages "$file" | cut -c24-)
# waite tell cURL finish saving the downloaded data to the file
# otherwise the pdf_pages count will be (null)
while : ; do
    [[ $pdf_pages != "(null)" ]] && break
    sleep 0.1
    pdf_pages=$(mdls -n kMDItemNumberOfPages "$file" | cut -c24-)
    #echo "$generated_pngs $pdf_pages"
done
if ! [[ "$generated_pngs" -eq "$pdf_pages" ]] ; then
    convert -density 400 $file processing/pic.png 2>/dev/null
    generated_pngs=$(ls processing/ | wc -l | sed 's/ //g')
    #
    #  -density 400       Set the horizontal resolution of the image
    #
    #  This will create one picture for every PDF page with the following
    #  naming convention pic-<NUM>.
fi

if [[ $generated_pngs -eq '0' ]] ; then
    msg_error "\n  failed to extract, please check your PDF \n"
    exit 1
else
    echo "  $(ls processing/ | wc -l | sed 's/ //g') PNGs were generated."
fi
echo ""

## 2. PNG's to MP4
msg_status "> rendering movie...\n"
ffmpeg -f image2 -r 1/8 -i processing/pic-%01d.png -vcodec mjpeg -qscale 8 $output_name.mov 2>/dev/null
echo "  $output_name.mov was successfully created"
read -p "  would you like to reveal it in finder? [y/n] " user_input
case $user_input in
 y|yes|Yes|sure) open . & ;;
esac

echo "  cleaning... "
rm -rf processing
#
# ffmpeg -i input_file.mp4 -acodec copy -vcodec copy -f mov output_file.mov
# ffmpeg -r 1/8 -i processing/pic-%01d.png -c:v libx264 -r 5 -pix_fmt yuv420p $output_name.mp4 2>/dev/null

#  -r 1/8             Displays each image for 8 seconds
#  -i pic-%02d.png    Read all images from the current folder with the prefix
#                     pic-, a following number of 2 digits (%02d) and an