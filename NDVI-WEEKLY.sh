#!/bin/bash
#Usage: bash update_NDVI-WEEKLY.sh DATE_LIST OUTPUT_PATH
#Example: bash update_NDVI-WEEKLY.sh DATE_LIST.txt OUTPUT_PATH

DATE_LIST=$1
OVERWRITE=$2
OUTPUT_PATH=$3

# Initialize variables
NDVI_WEEKLY_PATH=$OUTPUT_PATH'/NDVI-WEEKLY'
NDVI_DAILY_PATH=$OUTPUT_PATH'/NDVI-DAILY'
TARGET_DATA_PREFIX='NDVI-WEEKLY_'

while read LINE
do
    echo "----------------Update $LINE data----------------"

    YEAR=${LINE:0:4} # 2020
    WEEK_NUMBER=${LINE:5:2} # 01
    DATE=${LINE:5} # 01_2020.01.01_2020.01.07
    START_DATE=${LINE:8:10} # 2020.01.01
    END_DATE=${LINE:19:10} # 2020.01.07

    TARGET_OUTPUT_PATH=$NDVI_WEEKLY_PATH'/'$YEAR
    TARGET_DATA_NAME=$TARGET_OUTPUT_PATH'/'$TARGET_DATA_PREFIX$LINE'.tif'
    mkdir -p $TARGET_OUTPUT_PATH
    cd $TARGET_OUTPUT_PATH

    if [ ! -f $TARGET_DATA_NAME ] || [ $OVERWRITE = '-o' ] ; then
        echo "$LINE Job started"

        # Init File
        DAILY_DATE=$(date -d "${END_DATE//./} -6 days" +"%Y.%m.%d")
        DAILY_NAME='NDVI-DAILY_'$DAILY_DATE
        DAILY_PATH=$NDVI_DAILY_PATH'/'${DAILY_DATE:0:4}'/'$DAILY_NAME'.tif'
        DAILY_TMP_PATH=$TARGET_OUTPUT_PATH'/'$DAILY_NAME'.tmp.tif'
        echo "gdal_translate: "$DAILY_PATH
        gdal_translate -a_nodata none -co "COMPRESS=LZW" $DAILY_PATH $DAILY_TMP_PATH

        BAND_PARAMETER='-A '$DAILY_TMP_PATH
        CALC='A*(A<=250)'

        for (( i=2; i <= 7; ++i ))
        do
            CHAR=$( echo '' | awk '{printf "%c%s", NR+63+'$i', $0}')
            (( COUNTDOWN_DAY=7-i ))

            DAILY_DATE=$(date -d "${END_DATE//./} -$COUNTDOWN_DAY days" +"%Y.%m.%d")
            DAILY_NAME='NDVI-DAILY_'$DAILY_DATE
            DAILY_PATH=$NDVI_DAILY_PATH'/'${DAILY_DATE:0:4}'/'$DAILY_NAME'.tif'
            DAILY_TMP_PATH=$TARGET_OUTPUT_PATH'/'$DAILY_NAME'.tmp.tif'
            echo "gdal_translate: "$DAILY_PATH
            gdal_translate -a_nodata none -co "COMPRESS=LZW" $DAILY_PATH $DAILY_TMP_PATH

            BAND_PARAMETER=$BAND_PARAMETER' -'$CHAR' '$DAILY_TMP_PATH

            CALC='maximum('$CALC','$CHAR'*('$CHAR'<=250))'
        done

        CALC='('$CALC')'
        echo "gdal_calc - BAND_PARAMETER: "$BAND_PARAMETER
        echo "gdal_calc - CALC: "$CALC

        # background 0, conus 1-250, Int16
        gdal_calc.py $BAND_PARAMETER --outfile=$TARGET_DATA_NAME'.tmp.tif' --calc=$CALC --co COMPRESS=LZW
        # background 0, conus 1-250, Byte
        gdal_translate -ot Byte -co "COMPRESS=LZW" $TARGET_DATA_NAME'.tmp.tif' $TARGET_DATA_NAME'.tmp.2.tif'
        # background nodata(255), conus 1-250, Byte
        gdal_calc.py -A $TARGET_DATA_NAME'.tmp.2.tif' --outfile=$TARGET_DATA_NAME --calc='(255*(A==0)+A*(A>0))' --NoDataValue=255 --co COMPRESS=LZW --overwrite
        rm *'.tmp'*

        NDVI_MULTIYEAR_PATH=$OUTPUT_PATH'/NDVI-MULTIYEAR-WEEKLY'

        bash NDVI-MULTIYEAR-WEEKLY.sh $WEEK_NUMBER $NDVI_WEEKLY_PATH NDVI-WEEKLY $NDVI_MULTIYEAR_PATH NDVI-MULTIYEAR-WEEKLY MEAN
        bash NDVI-MULTIYEAR-WEEKLY.sh $WEEK_NUMBER $NDVI_WEEKLY_PATH NDVI-WEEKLY $NDVI_MULTIYEAR_PATH NDVI-MULTIYEAR-WEEKLY MEDIAN
        bash NDVI-MULTIYEAR-WEEKLY.sh $WEEK_NUMBER $NDVI_WEEKLY_PATH NDVI-WEEKLY $NDVI_MULTIYEAR_PATH NDVI-MULTIYEAR-WEEKLY MAX
        bash NDVI-MULTIYEAR-WEEKLY.sh $WEEK_NUMBER $NDVI_WEEKLY_PATH NDVI-WEEKLY $NDVI_MULTIYEAR_PATH NDVI-MULTIYEAR-WEEKLY MIN

    else
        echo "$DATE data exist, remove from $1"
        sed -i -e "/$DATE/d" $1
    fi

    echo "$LINE Job done"

done < $1
