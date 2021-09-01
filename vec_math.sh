vec3() {
    eval "$1=($2 $3 $4)"
}

vec3_add() {
    local -a a=("${!2}")
    local -a b=("${!3}")

    local ret
    add ${a[0]} ${b[0]}; local x=$ret
    add ${a[1]} ${b[1]}; local y=$ret
    add ${a[2]} ${b[2]}; local z=$ret

    vec3 $1 $x $y $z
}

vec3_sub() {
    local -a a=("${!2}")
    local -a b=("${!3}")

    local ret
    sub ${a[0]} ${b[0]}; local x=$ret
    sub ${a[1]} ${b[1]}; local y=$ret
    sub ${a[2]} ${b[2]}; local z=$ret

    vec3 $1 $x $y $z
}


vec3_mul() {
    local -a a=("${!2}")
    local -a b=("${!3}")

    local ret
    mul ${a[0]} ${b[0]}; local x=$ret
    mul ${a[1]} ${b[1]}; local y=$ret
    mul ${a[2]} ${b[2]}; local z=$ret

    vec3 $1 $x $y $z
}

vec3_mulf() {
    local -a a=("${!2}")
    local f=$3

    local ret
    mul ${a[0]} $f; local x=$ret
    mul ${a[1]} $f; local y=$ret
    mul ${a[2]} $f; local z=$ret

    vec3 $1 $x $y $z
}

vec3_divf() {
    local -a a=("${!2}")
    local f=$3

    local ret
    div ${a[0]} $f; local x=$ret
    div ${a[1]} $f; local y=$ret
    div ${a[2]} $f; local z=$ret

    vec3 "$1" "$x" "$y" "$z"
}

vec3_dot() {
    local -a a=("${!1}")
    local -a b=("${!2}")
    mul ${a[0]} ${b[0]}; local x=$ret
    mul ${a[1]} ${b[1]}; local y=$ret
    mul ${a[2]} ${b[2]}; local z=$ret
    ((ret = x + y + z))
}

vec3_truncate() {
    local -a a=("${!2}")

    local ret
    truncate ${a[0]}; local x=$ret
    truncate ${a[1]}; local y=$ret
    truncate ${a[2]}; local z=$ret

    vec3 $1 $x $y $z
}

vec3_sqrt() {
    local -a a=("${!2}")

    local ret
    sqrt ${a[0]}; local x=$ret
    sqrt ${a[1]}; local y=$ret
    sqrt ${a[2]}; local z=$ret

    vec3 $1 $x $y $z
}

vec3_normalize() {
    local -a vec=("${!2}")
    local ret
    vec3_dot 'vec[@]' 'vec[@]'; local vec_2=$ret
    inv_sqrt $vec_2; local inv_length=$ret
    vec3_mulf $1 vec[@] $inv_length
}

vec3_to_fp() {
    local ret
    to_fp $2; local x=$ret
    to_fp $3; local y=$ret
    to_fp $4; local z=$ret
    vec3 $1 $x $y $z
}

vec3_clamp_0_1() {
    local -a a=("${!2}")

    local ret
    clamp_0_1 ${a[0]}; local x=$ret
    clamp_0_1 ${a[1]}; local y=$ret
    clamp_0_1 ${a[2]}; local z=$ret

    vec3 $1 $x $y $z
}

vec3_test() {
    local -a x=(2 -2 3)
    local -a y=(-2 2 -3)
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
