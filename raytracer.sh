#!/bin/bash
set -e

source ./utils.sh
source ./math.sh

IMAGE_WIDTH=64
IMAGE_HEIGHT=64
NUM_PROCS=4
OUTPUT=$1
if [ -z "$OUTPUT" ]
then
    fatal "Usage: ./raytracer.sh output.ppm"
fi

rgb_scaling=$(to_fp 255.99)
half=$(to_fp 0.5)
image_width_fp=$(to_fp ${IMAGE_WIDTH})
image_height_fp=$(to_fp ${IMAGE_HEIGHT})
ray_epsilon=$(to_fp 0.01)

sphere_radius=$(to_fp 2)
vec3_to_fp sphere_center 0.0 0.0 3.0
vec3_to_fp sphere_color 0.3 0.3 0.3

shadow_center=$(to_fp 3.75)
shadow_radius=$(to_fp 5.5)

plane_y=$(to_fp -2)
vec3_to_fp plane_color_1 0.6 0.6 0.6
vec3_to_fp plane_color_2 0.1 0.1 0.1

vec3_to_fp light1_pos -2 4 1
vec3_to_fp light1_col 20 3 3

vec3_to_fp light2_pos 2 4 1
vec3_to_fp light2_col 3 20 3

print $rgb_scaling
echo $rgb_scaling
print $half
echo $half
print $image_width_fp
echo $image_width_fp
print $image_height_fp
echo $image_height_fp
print $ray_epsilon
echo $ray_epsilon
print $sphere_radius
echo $sphere_radius
print $shadow_center
echo $shadow_center
print $shadow_radius
echo $shadow_radius
print $plane_y
echo $plane_y

# requires hit_t hit_point and hit_normal in scope
sphere_intersect() {
    local hit_t_out=$1
    local hit_point_out=$2
    local hit_normal_out=$3

    local ray_origin=("${!4}")
    local ray_dir=("${!5}")

    vec3_sub oc ray_origin[@] sphere_center[@]
    local a=$(vec3_dot ray_dir[@] ray_dir[@])
    local half_b=$(vec3_dot oc[@] ray_dir[@])
    local oc_2=$(vec3_dot oc[@] oc[@])

    local radius_2=$(mul $sphere_radius $sphere_radius)
    local c=$(sub $oc_2 $radius_2)

    local half_b_2=$(mul $half_b $half_b)
    local ac=$(mul $a $c)
    local discrim=$(sub $half_b_2 $ac)

    if [ "$discrim" -gt 0 ]
    then
        local root=$(sqrt $discrim)
        local minus_half_b=$(sub 0 $half_b)

        local t=$(sub $minus_half_b $root)
        t=$(div $t $a)
        if [ $t -gt 0 ]
        then
            # p = o + t * d
            vec3_mulf tv ray_dir[@] $t
            vec3_add point ray_origin[@] tv[@]
            vec3_sub normal point[@] sphere_center[@]
            vec3_divf unit_normal normal[@] $sphere_radius

            eval $hit_point_out="(${point[@]})"
            eval $hit_normal_out="(${unit_normal[@]})"
            eval $hit_t_out="$t"
            return
        fi

        t=$(add $minus_half_b $root)
        t=$(div $t $a)
        if [ $t -gt 0 ]
        then
            # TODO is this branch the same as above? could refactor later
            # p = o + t * d
            vec3_mulf tv ray_dir[@] $t
            vec3_add point ray_origin[@] tv[@]
            vec3_sub normal point[@] sphere_center[@]
            vec3_divf unit_normal normal[@] $sphere_radius

            eval $hit_point_out="(${point[@]})"
            eval $hit_normal_out="(${unit_normal[@]})"
            eval $hit_t_out="$t"
            return
        fi
    fi

    eval $hit_t_out=-1
}

plane_intersect() {
    local hit_t_out=$1
    local hit_point_out=$2
    local hit_normal_out=$3

    local ray_origin=("${!4}")
    local ray_dir=("${!5}")

    local ray_o_y=${ray_dir[1]}
    if [ $ray_o_y -eq 0 ]
    then
        eval $hit_t_out=-1
    else
        # t = (c - o.y) / d.y
        local ray_y_dist=$(sub $plane_y $ray_o_y)
        local ray_d_y=${ray_dir[1]}
        local t=$(div $ray_y_dist $ray_d_y)
        if [ $t -gt 0 ] && [ $t -lt 2000000000 ]
        then
            vec3_mulf ray_scaled_d ray_dir[@] $t
            vec3_add point ray_origin[@] ray_scaled_d[@]

            eval $hit_t_out=$t
            eval $hit_point_out="(${point[@]})"
            eval $hit_normal_out="(0 ${scale[0]} 0)"
        else
            eval $hit_t_out=-1
        fi
    fi
}

# Takes out_origin as out_param 1
offset_origin() {
    local ray_origin=("${!2}")
    local hit_norm=("${!3}")
    vec3_mulf scaled_norm hit_norm[@] $ray_epsilon
    vec3_add origin scaled_norm[@] ray_origin[@]
    vec3 $1 ${origin[@]}
}

# doesn' account for shadowing, this is faked
# Takes out_col as out_param 1
light_contrib() {
    local point=("${!2}")
    local norm=("${!3}")
    local light_pos=("${!4}")
    local light_col=("${!5}")
    vec3_sub l light_pos[@] point[@]
    vec3_normalize lnorm l[@]
    local ndotl=$(vec3_dot norm[@] lnorm[@])

    if [ "$ndotl" -lt 0 ]
    then
        vec3 $1 0 0 0
    else
        vec3_mulf unscaled_out light_col[@] $ndotl
        local l2=$(vec3_dot l[@] l[@])
        vec3_divf $1 unscaled_out[@] $l2
    fi
}

# Takes color as out_param 1
trace() {
    local ray_origin=("${!2}")
    local ray_dir=("${!3}")
    local depth=$4
    local col=(0 0 0)


    if [ $depth -gt 3 ]
    then
        return
    else
        depth=$(( depth + 1 ))
    fi

    # vec3_print ray_origin[@]
    # vec3_print ray_dir[@]

    local hit_t_1=""
    local hit_point_1=""
    local hit_normal_1=""
    sphere_intersect hit_t_1 hit_point_1 hit_normal_1 ray_origin[@] ray_dir[@]
    plane_intersect hit_t_2 hit_point_2 hit_normal_2 ray_origin[@] ray_dir[@]

    # print $hit_t_1
    # if [ $hit_t_1 -lt 0 ]
    # then
    #     echo -n ""
    # else
    #     vec3_print hit_point_1[@]
    #     vec3_print hit_normal_1[@]
    # fi
    # print $hit_t_2
    # if [ $hit_t_2 -lt 0 ]
    # then
    #     echo -n ""
    # else
    #     vec3_print hit_point_2[@]
    #     vec3_print hit_normal_2[@]
    # fi
    # echo "==========="

    if [ $hit_t_1 -gt $ray_epsilon ]
    then
        # specular reflection
        offset_origin new_origin hit_point_1[@] hit_normal_1[@]

        # reflect
        local scalar=$(vec3_dot hit_normal_1[@] ray_dir[@])
        scalar=$(mul_by_2 $scalar)
        vec3_mulf refl_a hit_normal_1[@] $scalar
        vec3_sub new_dir ray_dir[@] refl_a[@]

        trace traced_col new_origin[@] new_dir[@] $depth

        light_contrib out_col1 \
            hit_point_1[@] \
            hit_normal_1[@] \
            light1_pos[@] \
            light1_col[@]
        light_contrib out_col2 \
            hit_point_1[@] \
            hit_normal_1[@] \
            light2_pos[@] \
            light2_col[@]

        vec3_add col col[@] out_col1[@]
        vec3_add col col[@] out_col2[@]
        vec3_add col col[@] traced_col[@]

        vec3 base_col ${sphere_color[@]}
        vec3_mul col base_col[@] col[@]
    else
        if [ $hit_t_2 -gt $ray_epsilon ]
        then
            local light_col=(0 0 0)
            local hit_p_x=${hit_point_2[0]}
            local hit_p_z=${hit_point_2[2]}

            # Use equation of a circle to fake shadow
            local shadow_offset_z=$(sub $hit_p_z $shadow_center)
            local shadow_offset_x_2=$(mul $hit_p_x $hit_p_x)
            local shadow_offset_z_2=$(mul $shadow_offset_z $shadow_offset_z)
            local hit_dist_2=$(add $shadow_offset_x_2 $shadow_offset_z_2)

            if [ $hit_dist_2 -gt $shadow_radius ]
            then
                light_contrib out_col1 \
                    hit_point_2[@] \
                    hit_normal_2[@] \
                    light1_pos[@] \
                    light1_col[@]

                light_contrib out_col2 \
                    hit_point_2[@] \
                    hit_normal_2[@] \
                    light2_pos[@] \
                    light2_col[@]

                vec3_add light_col light_col[@] out_col1[@]
                vec3_add light_col light_col[@] out_col2[@]
            fi

            # Calculate checkerboard pattern
            # TODO: Is there a better way?
            local half=$(( scale / 2 ))
            local hit_p_x=$(( hit_p_x % scale ))
            local hit_p_z=$(( hit_p_z % scale ))

            # shitty hack
            if [ $hit_p_x -lt 0 ]
            then
                hit_p_x=$(add $hit_p_x $scale)
            fi

            hit_p_x=$(abs $hit_p_x)
            hit_p_z=$(abs $hit_p_z)

            local base_col=(0 0 0)
            if [ $hit_p_x -gt $half ] && [ $hit_p_z -gt $half ]
            then
                vec3 base_col ${plane_color_1[@]}
            else
                if [ $hit_p_x -lt $half ] && [ $hit_p_z -lt $half ]
                then
                    vec3 base_col ${plane_color_1[@]}
                else
                    vec3 base_col ${plane_color_2[@]}
                fi
            fi

            vec3_mul col light_col[@] base_col[@]
        fi
    fi

    vec3 $1 ${col[@]}
}

worker() {
    WORKER_INDEX=$1
    if [ "$WORKER_INDEX" -gt $NUM_PROCS ]
    then
        fatal "Worker index ${WORKER_INDEX} out of bounds"
    fi

    LOG_PREFIX="[Worker ${WORKER_INDEX}]"
    log "Hello from worker ${WORKER_INDEX}"

    local output_file="${OUTPUT}-${WORKER_INDEX}.txt"
    # Create the file
    >"$output_file"

    log "scale ${scale}, digits: ${frac_digits}"

    local image_min_y=$(( (WORKER_INDEX - 1) * IMAGE_HEIGHT / NUM_PROCS ))
    local image_max_y=$(( WORKER_INDEX * IMAGE_HEIGHT / NUM_PROCS ))
    local image_max_x=$(( IMAGE_WIDTH ))

    log "min_y ${image_min_y}, max_y: ${image_max_y}, max_x: ${image_max_x}"
    for ((y=${image_min_y};y<${image_max_y};y++)); do
        local y_fp=$(to_fp $y)
        local v=$(div $y_fp $image_height_fp)

        local v2=$(mul_by_2 $v)
        local ray_dir_y=$(sub $scale $v2)

        log "============ Processing ${y}/${image_max_y} ================"
        for ((x=0;x<${image_max_x};x++)); do
            # log "========= Processing ${y}/${image_max_y} ${x}/${image_max_x}"
            local x_fp=$(to_fp $x)
            local rgb=(0 0 0)

            local u=$(div $x_fp $image_width_fp)

            local u2=$(mul_by_2 $u)
            local ray_dir_x=$(sub $u2 $scale)

            local ray_dir=($ray_dir_x $ray_dir_y $scale)
            vec3_normalize d ray_dir[@]

            local o=(0 0 0)
            trace rgb o[@] d[@] 0

            # vec3_print rgb[@]

            vec3_clamp_0_1 rgb rgb[@]

            vec3_sqrt rgb rgb[@] # gamma correction
            vec3_mulf rgb rgb[@] $rgb_scaling
            vec3_truncate rgb rgb[@] # shitty tonemap

            echo -n " ${rgb[0]} ${rgb[1]} ${rgb[2]}" >> "$output_file"
        done;
        # add a newline to the output
        echo "" >> "$output_file"
    done;

    log "============ Processing done =============="
}

main() {
    log "Launching ray tracer with ${NUM_PROCS} processes," \
        "${IMAGE_WIDTH}x${IMAGE_HEIGHT} image";

    for ((i=0;i<NUM_PROCS;i++)); do
        local idx=$((i + 1))
        worker $idx &
    done

    wait
    log "Finished ray tracing, gathering results..."
    echo -e "P3 ${IMAGE_WIDTH} ${IMAGE_HEIGHT}\n255\n\n" > $OUTPUT

    for ((i=0;i<NUM_PROCS;i++)); do
        local idx=$((i + 1))
        echo "$(<"${OUTPUT}-${idx}.txt")" >> $OUTPUT
        rm "${OUTPUT}-${idx}.txt"
    done

    exit 0
}

main
