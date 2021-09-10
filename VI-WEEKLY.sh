#!/bin/bash
#Usage: bash update_VI-WEEKLY.sh DATE_LIST DATA_TYPE OUTPUT_PATH
#Example: bash update_VI-WEEKLY.sh DATE_LIST.txt MVCI OUTPUT_PATH

DATE_LIST=$1
DATA_TYPE=$2
OVERWRITE=$3
OUTPUT_PATH=$4

# Initialize variables
VI_WEEKLY_PATH=$OUTPUT_PATH'/'$DATA_TYPE'-WEEKLY'
NDVI_WEEKLY_PATH=$OUTPUT_PATH'/NDVI-WEEKLY'
NDVI_MULTIYEAR_PATH=$OUTPUT_PATH'/NDVI-MULTIYEAR-WEEKLY'

TARGET_DATA_PREFIX=$DATA_TYPE'-WEEKLY'

while read LINE
do
    echo "----------------Update $LINE data----------------"

    YEAR=${LINE:0:4} # 2020
    WEEK_NUMBER=${LINE:5:2} # 01
    DATE=${LINE:5} # 01_2020.01.01_2020.01.07
    START_DATE=${LINE:8:10} # 2020.01.01
    END_DATE=${LINE:19:10} # 2020.01.07

    TARGET_OUTPUT_PATH=$VI_WEEKLY_PATH'/'$YEAR'/'
    TARGET_DATA_NAME=$VI_WEEKLY_PATH'/'$YEAR'/'$TARGET_DATA_PREFIX'_'$YEAR'_'$DATE'.tif'

    NDVI_MEAN_FILE=$NDVI_MULTIYEAR_PATH'/NDVI-MULTIYEAR-WEEKLY_'$WEEK_NUMBER'_MEAN.tif'
    NDVI_MAX_FILE=$NDVI_MULTIYEAR_PATH'/NDVI-MULTIYEAR-WEEKLY_'$WEEK_NUMBER'_MAX.tif'
    NDVI_MIN_FILE=$NDVI_MULTIYEAR_PATH'/NDVI-MULTIYEAR-WEEKLY_'$WEEK_NUMBER'_MIN.tif'
    NDVI_MEDIAN_FILE=$NDVI_MULTIYEAR_PATH'/NDVI-MULTIYEAR-WEEKLY_'$WEEK_NUMBER'_MEDIAN.tif'
    NDVI_WEEKLY_FILE=$NDVI_WEEKLY_PATH'/'$YEAR'/NDVI-WEEKLY_'$YEAR'_'$DATE'.tif'
    NDVI_WEEKLY_PRE_FILE=$NDVI_WEEKLY_PATH'/'$(($YEAR - 1))'/NDVI-WEEKLY_'$(($YEAR - 1))'_'$WEEK_NUMBER*'.tif'

    mkdir -p $TARGET_OUTPUT_PATH

    if [ ! -f $TARGET_DATA_NAME ] || [ $OVERWRITE = '-o' ] ; then
        if [ $DATA_TYPE == 'MVCI' ]; then
            gdal_calc.py --calc "(250*(((A-B)/B)>=1.25)+0*(((A-B)/B)<=-1.25)+(100*((A-B)/B)+125)*logical_and(((A-B)/B)<1.25,((A-B)/B)>-1.25))" --format GTiff -A $NDVI_WEEKLY_FILE -B $NDVI_MEAN_FILE --co COMPRESS=LZW --outfile $TARGET_DATA_NAME'.tmp.tif'
        elif [ $DATA_TYPE == 'VCI' ]; then
            gdal_calc.py --calc "((250*(A-B))/(C-B))*logical_and(A<=250,A>=0)" --co COMPRESS=LZW -A $NDVI_WEEKLY_FILE -B $NDVI_MIN_FILE -C $NDVI_MAX_FILE --outfile $TARGET_DATA_NAME'.tmp.tif'
        elif [ $DATA_TYPE == 'RVCI' ] || [ $DATA_TYPE == 'RNDVI' ]; then
            gdal_translate -ot Int16 -co "COMPRESS=LZW" $NDVI_WEEKLY_PRE_FILE $TARGET_DATA_NAME'.tmp.prendvi.tif'
            gdal_calc.py --calc "(0*((A-B)/B<=-1.25)+250*(((A-B)/B)>=1.25)+(100*((A-B)/B)+125)*logical_and(((A-B)/B)<1.25,((A-B)/B)>-1.25))" --co COMPRESS=LZW --NoDataValue=0 -A $NDVI_WEEKLY_FILE -B $TARGET_DATA_NAME'.tmp.prendvi.tif' --outfile $TARGET_DATA_NAME'.tmp.tif'
        elif [ $DATA_TYPE == 'RMVCI' ] || [ $DATA_TYPE == 'RMNDVI' ]; then
            gdal_calc.py --calc "(0*((A-B)/B<=-1.25)+250*(((A-B)/B)>=1.25)+(100*((A-B)/B)+125)*logical_and(((A-B)/B)<1.25,((A-B)/B)>-1.25))" --co COMPRESS=LZW --NoDataValue=0 -A $NDVI_WEEKLY_FILE -B $NDVI_MEDIAN_FILE --outfile $TARGET_DATA_NAME'.tmp.tif'
        fi
        gdal_calc.py -A $TARGET_DATA_NAME'.tmp.tif' -B $NDVI_WEEKLY_FILE --outfile=$TARGET_DATA_NAME'.tmp.2.tif' --calc='(255*(B==255)+A*logical_and(A<=250,A>=0)*logical_and(B<=250,B>=0)+0*(A==255)*logical_and(B<=250,B>=0))' --NoDataValue=255 --co COMPRESS=LZW --overwrite
        gdal_translate -ot Byte -co "COMPRESS=LZW" $TARGET_DATA_NAME'.tmp.2.tif' $TARGET_DATA_NAME

        rm $TARGET_DATA_NAME'.tmp'*

        echo "$LINE Job done"
    else
        echo "$DATE data exist, remove from $1"
        cd $PROGRAM_WEEKLY_PATH
        sed -i -e "/$DATE/d" $1
    fi

done < $1
