vec3() {
    local __target=$1
    eval $__target="($2 $3 $4)"
}

vec3_add() {
    local a=("${!2}")
    local b=("${!3}")

    local x=$(add ${a[0]} ${b[0]})
    local y=$(add ${a[1]} ${b[1]})
    local z=$(add ${a[2]} ${b[2]})

    vec3 $1 $x $y $z
}

vec3_sub() {
    local a=("${!2}")
    local b=("${!3}")

    local x=$(sub ${a[0]} ${b[0]})
    local y=$(sub ${a[1]} ${b[1]})
    local z=$(sub ${a[2]} ${b[2]})

    vec3 $1 $x $y $z
}


vec3_mul() {
    local a=("${!2}")
    local b=("${!3}")

    local x=$(mul ${a[0]} ${b[0]})
    local y=$(mul ${a[1]} ${b[1]})
    local z=$(mul ${a[2]} ${b[2]})

    vec3 $1 $x $y $z
}

vec3_mulf() {
    local a=("${!2}")
    local f=$3

    local x=$(mul ${a[0]} $f)
    local y=$(mul ${a[1]} $f)
    local z=$(mul ${a[2]} $f)

    vec3 $1 $x $y $z
}

vec3_divf() {
    local a=("${!2}")
    local f=$3

    local x=$(div ${a[0]} $f)
    local y=$(div ${a[1]} $f)
    local z=$(div ${a[2]} $f)

    vec3 $1 $x $y $z
}

vec3_dot() {
    local a=("${!1}")
    local b=("${!2}")

    local x=$(mul ${a[0]} ${b[0]})
    local y=$(mul ${a[1]} ${b[1]})
    local z=$(mul ${a[2]} ${b[2]})

    echo $((x + y + z))
}

vec3_truncate() {
    local a=("${!2}")

    local x=$(truncate ${a[0]})
    local y=$(truncate ${a[1]})
    local z=$(truncate ${a[2]})

    vec3 $1 $x $y $z
}

vec3_sqrt() {
    local a=("${!2}")

    local x=$(sqrt ${a[0]})
    local y=$(sqrt ${a[1]})
    local z=$(sqrt ${a[2]})

    vec3 $1 $x $y $z
}

vec3_normalize() {
    local vec=("${!2}")
    local vec_2=$(vec3_dot vec[@] vec[@])
    local inv_length=$(inv_sqrt $vec_2)
    vec3_mulf $1 vec[@] $inv_length
}

vec3_to_fp() {
    vec3 $1 $(to_fp $2) $(to_fp $3) $(to_fp $4)
}

vec3_clamp_0_1() {
    local a=("${!2}")

    local x=$(clamp_0_1 ${a[0]})
    local y=$(clamp_0_1 ${a[1]})
    local z=$(clamp_0_1 ${a[2]})

    vec3 $1 $x $y $z
}

vec3_test() {
    local x=(2 -2 3)
    local y=(-2 2 -3)
    # vec3_clamp_0_1 res x[@]
    # echo ${res[@]}

    # vec3_add res x[@] y[@]
    # echo ${res[@]}


    local s=$(( scale * scale ))
    vec3_mulf res_1 x[@] s
    vec3_mulf res_2 y[@] s

    vec3_mul res res_1[@] res_2[@]
    echo ${res[@]}
}
