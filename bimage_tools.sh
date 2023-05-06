#!/usr/bin/env bash


_bimage_animated_gif_help()
{
    echo
    echo "Convert MOV to Animated GIF"
    echo "  bimage animated_gif [-s WxH] [-S] input_file_name [output_file_name]"
    echo
    echo "  -s -> ffmpeg -s option for setting Width and Height limits, defaults to 800x600"
    echo "  -S use souce size to Width and Height"
    echo "  <input_file_name> - the MOV file to convert"
    echo "  <output_file_name> - the file for the animated GIF results, default to 'out.gif'"
}

bimage_animated_gif()
{
    declare FF_SIZE_OPTION=("-s" "1280x720")
    declare USE_GIFSICLE=false

    while (( $# )); do

        case "$1" in

        -s)
            # set scale size
            FF_SIZE_OPTION=("-s" "$2")
            shift; shift;
            ;;

        -S)
            # use default scale size (same as input)
            FF_SIZE_OPTION=()
            shift;
            ;;

        -G)
        #  Use gifsicle
            USE_GIFSICLE=true
            shift;
            ;;

        *)
            break
            ;;

        esac

    done

    declare INPUT_FILE="$1"
    declare OUTPUT_FILE="${2:-out.gif}"

    if [[ -z "${INPUT_FILE}" ]] || ! [[ -r "${INPUT_FILE}" ]]; then
        echo "Cannot read input file: '${INPUT_FILE}'"
        exit 2
    fi

    if ! type -t ffmpeg &> /dev/null; then
        echo "ffmpeg is required. Install with 'brew install ffmpeg'"
        exit 3
    fi

    if $USE_GIFSICLE; then
        if ! type -t gifsicle &> /dev/null; then
            echo "gifsicle is required. Install with 'brew install gifsicle'"
            exit 3
        fi

        ffmpeg -i "${INPUT_FILE}" "${FF_SIZE_OPTION[@]}" -pix_fmt rgb24 -r 10 -f gif -loglevel fatal - \
            | gifsicle --optimize=3 --delay=3 > "${OUTPUT_FILE}"

    else
        # maybe use image magick instead of gifsicle
        if ! type -t convert &> /dev/null; then
            echo "imagemagick is required. Install with 'brew install imagemagick'"
            exit 3
        fi

        declare WORK_FOLDER="bimage_temp"

        mkdir -p "${WORK_FOLDER}" || exit 1

        ffmpeg -i "${INPUT_FILE}" "${FF_SIZE_OPTION[@]}" -pix_fmt rgb24 -r 10 -f gif -loglevel fatal "${WORK_FOLDER}/ffout%3d.png"

        convert -delay 8 -loop 0 "${WORK_FOLDER}"/ffout*.png "${OUTPUT_FILE}"

        rm -rf "${WORK_FOLDER}"

    fi
}

_bimage_convert_to_png_help()
{
    echo "bimage convert_to_png [files]"

    echo "converts all image files referenced to PNG format"
    echo "stores converted results in same folder as original"
    echo
}

bimage_convert_to_png()
{
    local IMAGES=("$@")
    magick mogrify -monitor -format png "${IMAGES[@]}"
}

_bimage_add_meta_date_label_help()
{
    echo
    echo "bimage add_meta_label <files>"
    echo
    echo "  Adds a label inside each image with the Date the image was taken"
    echo
    echo "  Stores converted results in folder: ./labeled_images/labeled"
    echo "  Copies any files with errors to:: ./labeled_images/errors"
    echo
    echo "  <files> can be a glob or a single file. Does not recurse folders"
    echo "  Possible errors are the file cannot be read as an image, does not have an EXIT Date value, etc."
    echo
}

bimage_add_meta_date_label()
{
    if (( $# == 0 )); then
        _bimage_add_meta_date_label_help
        return 1
    fi

    declare DESTDIR="./labeled_images"
    declare OUTDIR="${DESTDIR}/labeled"
    declare ERRDIR="${DESTDIR}/errors"

    mkdir -p "${OUTDIR}"
    mkdir -p "${ERRDIR}"

    for SRC_IMAGE in "$@"; do

        declare IMAGE
        IMAGE="$(basename "${SRC_IMAGE}")"

        declare -a EXIF_DATA
        if ! _get_date_and_size "${SRC_IMAGE}" EXIF_DATA; then
            printf "Cannot get EXIF data from SRC_IMAGE: %s\n" "${SRC_IMAGE}" >&2
            cp "${SRC_IMAGE}" "${ERRDIR}/${IMAGE}"
            continue
        fi

        # EXIF_DATA=([0]="3888" [1]="2592" [2]="2018:07:21 17:20:43")
        # [2] might not exist
        declare LABEL_WIDTH="${EXIF_DATA[0]}"
        (( LABEL_WIDTH = LABEL_WIDTH / 5 ))

        declare EXIF_DATE
        if (( "${#EXIF_DATA[@]}" >= 3 )); then
            # "2018:07:21 17:20:43" --> "2018-07-21"
            EXIF_DATE="${EXIF_DATA[2]}"
            EXIF_DATE="${EXIF_DATE%% *}"
            EXIF_DATE="${EXIF_DATE//:/-}"
        fi

        if [[ -z "${EXIF_DATE}" ]] || ! convert "${SRC_IMAGE}" \
                \( \
                -size "${LABEL_WIDTH}" \
                -background none \
                -fill white label:"${EXIF_DATE}" \
                \) \
                -gravity SouthEast \
                -composite "${OUTDIR}/${IMAGE}"
        then
            printf "Could not label image: %s\n" "${SRC_IMAGE}" >&2
            cp "${SRC_IMAGE}" "${ERRDIR}/${IMAGE}"
            continue
        fi

        printf "%s -> %s\n" "${SRC_IMAGE}" "${OUTDIR}/${IMAGE}"

    done

    return 0
}

_get_date_and_size()
{
    # $2 will be referenced and populated as an OUT ARRARY
    # 0 - Width
    # 1 - Height
    # 2 - EXIF:DateTimeOriginal

    declare SRC_IMAGE=$1
    declare -n _out_PARTS=$2  # NAMEREF!! goofy naming to avoid nameref name collisions
    declare DATA

    if ! DATA="$(identify -format '%w|%h|%[EXIF:DateTimeOriginal]' "${SRC_IMAGE}" 2> /dev/null )"; then
        return 1
    fi

    IFS='|' read -ra _out_PARTS <<< "${DATA}"

}
