#!/bin/bash
set -f

source ./utils.sh
source ./math.sh

IMAGE_WIDTH=64
IMAGE_HEIGHT=64
NUM_PROCS=4
OUTPUT=$1
if [[ ! $OUTPUT ]]; then
    fatal "Usage: ./raytracer.sh output.ppm"
fi

to_fp 255.99; rgb_scaling=$ret
to_fp 0.5; half=$ret
to_fp ${IMAGE_WIDTH}; image_width_fp=$ret
to_fp ${IMAGE_HEIGHT}; image_height_fp=$ret
to_fp 0.01; ray_epsilon=$ret

to_fp 2; sphere_radius=$ret
vec3_to_fp sphere_center 0.0 0.0 3.0
vec3_to_fp sphere_color 0.3 0.3 0.3

to_fp 3.75; shadow_center=$ret
to_fp 5.5; shadow_radius=$ret

to_fp -2; plane_y=$ret
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
    local ret
    vec3_dot ray_dir[@] ray_dir[@]; local a=$ret
    vec3_dot oc[@] ray_dir[@]; local half_b=$ret
    vec3_dot oc[@] oc[@]; local oc_2=$ret

    mul "$sphere_radius" "$sphere_radius"; local radius_2=$ret
    sub "$oc_2" "$radius_2"; local c=$ret

    mul "$half_b" "$half_b"; local half_b_2=$ret
    mul "$a" "$c"; local ac=$ret
    sub "$half_b_2" "$ac"; local discrim=$ret

    if ((discrim > 0)); then
        sqrt "$discrim"; local root=$ret
        sub 0 "$half_b"; local minus_half_b=$ret

        sub "$minus_half_b" "$root"
        div "$ret" "$a"; local t=$ret
        if ((t > 0)); then
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

        add "$minus_half_b" "$root"
        div "$ret" "$a"
        t=$ret
        if ((t > 0)); then
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
    if ((ray_o_y == 0)); then
        eval $hit_t_out=-1
    else
        # t = (c - o.y) / d.y
        local ret
        sub "$plane_y" "$ray_o_y"; local ray_y_dist=$ret
        local ray_d_y=${ray_dir[1]}
        div "$ray_y_dist" "$ray_d_y"
        local t=$ret
        if ((t > 0 && t < 2000000000)); then
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
    local -a ray_origin=("${!2}")
    local -a hit_norm=("${!3}")
    vec3_mulf scaled_norm hit_norm[@] $ray_epsilon
    vec3_add origin scaled_norm[@] ray_origin[@]
    vec3 $1 ${origin[@]}
}

# doesn' account for shadowing, this is faked
# Takes out_col as out_param 1
light_contrib() {
    local -a point=("${!2}")
    local -a norm=("${!3}")
    local -a light_pos=("${!4}")
    local -a light_col=("${!5}")
    vec3_sub l light_pos[@] point[@]
    vec3_normalize lnorm l[@]
    local ret
    vec3_dot norm[@] lnorm[@]; local ndotl=$ret

    if ((ndotl < 0)); then
        vec3 $1 0 0 0
    else
        vec3_mulf unscaled_out light_col[@] $ndotl
        vec3_dot l[@] l[@]; local l2=$ret
        vec3_divf $1 unscaled_out[@] $l2
    fi
}

# Takes color as out_param 1
trace() {
    local ray_origin=("${!2}")
    local ray_dir=("${!3}")
    local depth=$4
    local col=(0 0 0)


    if ((depth > 3)); then
        return
    else
        ((depth++))
    fi

    # vec3_print ray_origin[@]
    # vec3_print ray_dir[@]

    local hit_t_1=""
    local hit_point_1=""
    local hit_normal_1=""
    sphere_intersect hit_t_1 hit_point_1 hit_normal_1 ray_origin[@] ray_dir[@]
    plane_intersect hit_t_2 hit_point_2 hit_normal_2 ray_origin[@] ray_dir[@]

    # print $hit_t_1
    # if ((hit_t_1 < 0)); then
    #     echo -n ""
    # else
    #     vec3_print hit_point_1[@]
    #     vec3_print hit_normal_1[@]
    # fi
    # print $hit_t_2
    # if ((hit_t_2 < 0)); then
    #     echo -n ""
    # else
    #     vec3_print hit_point_2[@]
    #     vec3_print hit_normal_2[@]
    # fi
    # echo "==========="

    if ((hit_t_1 > ray_epsilon)); then
        # specular reflection
        offset_origin new_origin hit_point_1[@] hit_normal_1[@]

        # reflect
        local ret
        vec3_dot hit_normal_1[@] ray_dir[@]
        mul_by_2 "$ret"; local scalar=$ret
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
    elif ((hit_t_2 > ray_epsilon)); then
        local light_col=(0 0 0)
        local hit_p_x=${hit_point_2[0]}
        local hit_p_z=${hit_point_2[2]}

        # Use equation of a circle to fake shadow
        local ret
        sub "$hit_p_z" "$shadow_center"; local shadow_offset_z=$ret
        mul "$hit_p_x" "$hit_p_x"; local shadow_offset_x_2=$ret
        mul "$shadow_offset_z" "$shadow_offset_z"; local shadow_offset_z_2=$ret
        add "$shadow_offset_x_2" "$shadow_offset_z_2"; local hit_dist_2=$ret

        if ((hit_dist_2 > shadow_radius)); then
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
        if ((hit_p_x < 0)); then
          add "$hit_p_x" "$scale"; hit_p_x=$ret
        fi

        local ret
        abs "$hit_p_x"; hit_p_x=$ret
        abs "$hit_p_z"; hit_p_z=$ret

        local base_col=(0 0 0)
        if ((hit_p_x > half && hit_p_z > half)); then
            vec3 base_col ${plane_color_1[@]}
        elif ((hit_p_x < half && hit_p_z < half)); then
            vec3 base_col ${plane_color_1[@]}
        else
            vec3 base_col ${plane_color_2[@]}
        fi

        vec3_mul col light_col[@] base_col[@]
    fi

    vec3 $1 ${col[@]}
}

worker() {
    WORKER_INDEX=$1
    if ((WORKER_INDEX > NUM_PROCS)); then
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

    local ret rgb ray_dir o
    log "min_y ${image_min_y}, max_y: ${image_max_y}, max_x: ${image_max_x}"
    for ((y=${image_min_y};y<${image_max_y};y++)); do
        to_fp "$y"; local y_fp=$ret
        div "$y_fp" "$image_height_fp"; local v=$ret

        mul_by_2 "$v"; local v2=$ret
        sub "$scale" "$v2"; local ray_dir_y=$ret

        log "============ Processing ${y}/${image_max_y} ================"
        for ((x=0;x<${image_max_x};x++)); do
            # log "========= Processing ${y}/${image_max_y} ${x}/${image_max_x}"
            to_fp "$x"; local x_fp=$ret
            rgb=(0 0 0)

            div "$x_fp" "$image_width_fp"; local u=$ret

            mul_by_2 "$u"; local u2=$ret
            sub "$u2" "$scale"; local ray_dir_x=$ret

            ray_dir=($ray_dir_x $ray_dir_y $scale)
            vec3_normalize d ray_dir[@]

            o=(0 0 0)
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
