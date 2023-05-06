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
    echo "bimage add_meta_label [files]"

    echo "Adds a label inside the image with the Date the image was taken"
    echo "stores converted results in folder under the current folder: labeled_images"
    echo
}

bimage_add_meta_date_label()
{
    if (( $# == 0 )); then
        _bimage_add_meta_label_help
        return 1
    fi

    DESTDIR="./labeled_images"
    OUTDIR="${DESTDIR}/labeled"
    ERRDIR="${DESTDIR}/errors"

    mkdir -p "${OUTDIR}"
    mkdir -p "${ERRDIR}"

    for image in "$@"; do

        if ! EXIF_DATE="$(identify -format '%[EXIF:*]' "${image}" | grep 'exif:DateTimeOriginal')"; then
            printf "No EXIF Date in image: %s\n" "${image}" >&2
            cp "${image}" "${ERRDIR}/"
            continue
        fi

        # exif:DateTimeOriginal=2013:12:14 16:35:04
        #                       2013-12-14
        EXIF_DATE="${EXIF_DATE##*=}"
        EXIF_DATE="${EXIF_DATE%% *}"
        EXIF_DATE="${EXIF_DATE//:/-}"

        W=$(identify -format '%w' "${image}")
        (( W = W / 5 ))

        if ! convert "${image}" \( -size "${W}" \
                -background none \
                -fill white label:"${EXIF_DATE}" \
                \) -gravity SouthEast \
                -composite "${OUTDIR}/${image}"
        then
            printf "Could not label image: %s\n" "${image}" >&2
            cp "${image}" "${ERRDIR}/"
            continue
        fi

        printf "%s -> %s\n" "${image}" "${OUTDIR}/${image}"

    done
}
