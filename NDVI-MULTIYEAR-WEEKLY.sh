#!/bin/bash
#Usage: bash update_MULTIYEAR-WEEKLY.sh WEEK_NUMBER MISSDATA_PATH INPUT_DATA_PATH INPUT_DATA_PREFIX OUTPUT_DATA_PATH OUTPUT_DATA_PREFIX CALC_METHOD
#Example: bash update_MULTIYEAR-WEEKLY.sh 01 /SMAP_DATA/NDVI-WEEKLY NDVI-WEEKLY /SMAP_DATA/NDVI-MULTIYEAR-WEEKLY NDVI-MULTIYEAR-WEEKLY MAX

# Initialize variables
WEEK_NUMBER=$1
INPUT_DATA_PATH=$2
INPUT_DATA_PREFIX=$3
OUTPUT_DATA_PATH=$4
OUTPUT_DATA_PREFIX=$5
CALC_METHOD=$6

for WEEK_NUMBER in 0{1..9} {10..53}
do

    echo "----------------Update $LINE data----------------"
    OUTPUT_FILE=$OUTPUT_DATA_PATH'/'$OUTPUT_DATA_PREFIX'_'$WEEK_NUMBER'_'$CALC_METHOD'.tif'

    mkdir -p $OUTPUT_DATA_PATH
    cd $OUTPUT_DATA_PATH

    BANDS_PARAMETER=$(find $INPUT_DATA_PATH'/' -type f -name $INPUT_DATA_PREFIX'*_'$WEEK_NUMBER'_*.tif' | sed 's/.*/ & /' | awk '{printf "-%c%s", NR+64, $0}')
    BANDS_COUNT=$(find $INPUT_DATA_PATH'/' -type f -name $INPUT_DATA_PREFIX'*_'$WEEK_NUMBER'_*.tif' | wc -l)
    echo "BANDS_PARAMETER: "$BANDS_PARAMETER
    echo "BANDS_COUNT: "$BANDS_COUNT

    CALC='A*(A<=250)'
    ERROR_CODE=0
    for (( i=2; i < $BANDS_COUNT; i++ ))
    do
        CHAR=$( echo '' | awk '{printf "%c%s", NR+63+'$i', $0}')
        if [ $CALC_METHOD == 'MEAN' ] || [ $CALC_METHOD == 'MEDIAN' ]; then
            CALC=$CALC','$CHAR'*('$CHAR'<=250)'
        elif [ $CALC_METHOD == 'MAX' ]; then
            CALC='maximum('$CALC','$CHAR'*('$CHAR'<=250))'
        elif [ $CALC_METHOD == 'MIN' ]; then
            CALC='minimum('$CALC','$CHAR'*('$CHAR'<=250))'
        else
            echo "Please enter a valid calculation method ("$CALC_METHOD")."
            ERROR_CODE=1
            break
        fi
    done

    if [ $ERROR_CODE == 0 ]; then
        if [ $CALC_METHOD == 'MEAN' ]; then
            CALC='mean(['$CALC'],0)'
        elif [ $CALC_METHOD == 'MEDIAN' ]; then
            CALC='median(['$CALC'],0)'
        fi
        echo "CALC: "$CALC

        # background nodata(255), conus 1-250, Byte
        gdal_calc.py $BANDS_PARAMETER --outfile=$OUTPUT_FILE'.tmp.tif' --calc=$CALC --co COMPRESS=LZW --overwrite
        # background nodata(none), conus 1-250, Int16
        gdal_translate -ot Int16 -a_nodata none -co "COMPRESS=LZW" $OUTPUT_FILE'.tmp.tif' $OUTPUT_FILE
        rm $OUTPUT_FILE'.tmp'*

    elif [ $ERROR_CODE == 1 ]; then
        echo "Please enter a valid calculation method ('MEAN', 'MAX', 'MIN', 'MEDIAN')."
    fi

done
