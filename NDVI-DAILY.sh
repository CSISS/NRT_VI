#!/bin/bash
#Usage: bash NDVI-DAILY.sh date_list OUTPUT_PATH
#Example: bash NDVI-DAILY.sh date_list.txt OUTPUT_PATH

DATE_LIST=$1
OUTPUT_PATH=$2

# Initialize variables
DOWNLOAD_PATH=$OUTPUT_PATH'/CACHE'
USA_MASK='data/usa_mask.hdf'

# attach API requested from EOSDIS
NRT_ENDPOINT='https://nrt3.modaps.eosdis.nasa.gov/api/v2/content/archives/allData/6/MOD09GQ/Recent/MOD09GQ.A'
NRT_API='__ATTACH_API_HERE__' 

mkdir -p $DOWNLOAD_PATH
mkdir -p $OUTPUT_PATH

cd $PROGRAM_DAILY_PATH

while read LINE
do
    YEAR=${LINE:0:4}
    DOY=$(date -d ${LINE//./-} +%j)
    TARGET_DATA_PATH=$OUTPUT_PATH'/'$YEAR
    TARGET_FILENAME=NDVI-DAILY'_'$LINE.tif

    if [ $(ls $TARGET_DATA_PATH/$TARGET_FILENAME | wc -l) -eq 1 ]; then
        echo "$LINE data exist, remove from $1"
        cd $PROGRAM_DAILY_PATH
        sed -i -e "/$LINE/d" $DATE_LIST
    else

        echo "----------------Download NRT Data----------------"

        DIR="$DOWNLOAD_PATH/$LINE"
        mkdir -p $DIR
        cd $DIR

        wget $NRT_ENDPOINT$YEAR$DOY.h06v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h07v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h07v05.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h07v06.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h08v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h08v04.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h08v05.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h08v06.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h09v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h09v04.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h09v05.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h09v06.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h10v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h10v04.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h10v05.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h10v06.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h11v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h11v04.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h11v05.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h11v06.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h12v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h12v04.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h12v05.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h13v03.006.NRT.hdf --header "$NRT_API"
        wget $NRT_ENDPOINT$YEAR$DOY.h13v04.006.NRT.hdf --header "$NRT_API"

        echo "Donwload is complete"
        echo "--------------------------------------------"

        echo "----------------Check Data Integrity----------------"
        pattern="*.hdf"
        var2=$(ls $pattern | wc -l)
        echo "File number: $var2"

        if [ $(ls $DIR/*.NRT.hdf | wc -l) -eq 25 ]; then

            cd $PROGRAM_DAILY_PATH
            echo "----------------------------------------------------"

            echo "----------------Process Data----------------"

            # sh hdfdaily_dynamic.sh $LINE $2 $3 $4
            touch $DOWNLOAD_PATH/$LINE/hdffiles.txt
            cp /dev/null $DOWNLOAD_PATH/$LINE/hdffiles.txt
            for f in $(ls $DOWNLOAD_PATH/$LINE/*.NRT.hdf)
            do
                echo $f>>$DOWNLOAD_PATH/$LINE/hdffiles.txt
            done

            if [ ! -d "$DOWNLOAD_PATH/$LINE" ]; then
                mkdir $DOWNLOAD_PATH/$LINE
            fi

            echo $DOWNLOAD_PATH/$LINE/hdffiles.txt $USA_MASK $DOWNLOAD_PATH/$LINE/NDVI$LINE.hdf

            _ndvi_mosaic.x $DOWNLOAD_PATH/$LINE/hdffiles.txt $USA_MASK $DOWNLOAD_PATH/$LINE/NDVI$LINE.hdf
            echo "_ndvi_mosaic.x done"

            # bash togeotiffalbers_dynamic.sh $LINE $DOWNLOAD_PATH $OUTPUT_PATH
            mkdir -p $TARGET_DATA_PATH
            gdalwarp -t_srs EPSG:5070 -tr 250 -250 -ot Byte -co "COMPRESS=LZW" -cutline $PROGRAM_MAP_PATH'/us_boundary/us_boundary.shp' -crop_to_cutline -srcnodata 255 -dstnodata 255 -of GTiff $DOWNLOAD_PATH/$LINE/NDVI$LINE.hdf $TARGET_DATA_PATH/$TARGET_FILENAME

            echo "--------------------------------------------"
        else
            echo "ERROR: file number is less than 25"
            continue
        fi
    fi
done < $DATE_LIST
