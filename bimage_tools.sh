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
    declare FF_SIZE_OPTION="-s 800x600"

    while (( $# )); do

        case "$1" in

        -s)
            # set scale size
            FF_SIZE_OPTION="-s $2"
            shift; shift;
            ;;

        -S)
            # use default scale size (same as input)
            FF_SIZE_OPTION=
            shift;
            ;;

        *)
            break
            ;;

        esac

    done

    declare INPUT_FILE="$1"
    declare OUTPUT_FILE="${2:-out.gif}"

    # shellcheck disable=SC2086
    ffmpeg -i "${INPUT_FILE}" ${FF_SIZE_OPTION} -pix_fmt rgb24 -r 10 -f gif - \
        | gifsicle --optimize=3 --delay=3 > "${OUTPUT_FILE}"

# maybe use image magick instead of gifsicle
# will need to manage a temp directory for the frame gifs
# ffmpeg -i myvideo.mov -vf scale=1024:-1 -r 10 output/ffout%3d.png
# convert -delay 8 -loop 0 output/ffout*.png output/animation.gif

    # piping frames did not seem to work
    # ffmpeg -i "${INPUT_FILE}" -vf scale=1024:-1 -r 10 - \
    #     | convert -delay 8 -loop 0 - "${OUTPUT_FILE}"

}
