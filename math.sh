
scale="100000000"
frac_digits=${#scale}

add() ((ret = $1 + $2, 1))
sub() ((ret = $1 - $2, 1))

mul() {
    ((ret = $1 * $2 / scale, 1))
    if ((ret < 0 && $1 > 0 && $2 > 0)); then
      log "OVERFLOW DETECTED: $1 x $2 = $ret"
    fi
}
div() ((ret = $1 * scale / $2, 1))

div_by_2() ((ret = $1 >> 1, 1))
mul_by_2() ((ret = $1 << 1, 1))

truncate() ((ret = $1 / scale, 1))
abs() ((ret = $1 < 0 ? -$1 : $1, 1))
sqrt() {
    local x=$1
    if ((x < 0)); then
        fatal "arg passed to sqrt x was negative: ${x}"
        # TODO mul can exceed the precision needed so certain dot products get
        # weird
        # abs "$x"; x=$ret
        # echo 0
        # return
    fi

    div_by_2 "$x"
    local guess=$ret
    for i in {0..5}; do
        if ((guess==0)); then
          break
        fi
        div "$x" "$guess"
        add "$ret" "$guess"
        div_by_2 "$ret"
        guess=$ret
    done
    ret=$guess
}

# Convert a number to fixed point representation
to_fp() {
    local x=$1
    # Remove everything after the .
    local int_part=${x%.*}
    # Remove everything before the .
    local frac_part=${x#*.}
    if [[ $x == *.* ]]
    then
        frac_part=${frac_part:0:6}
    else
        frac_part=0
    fi
    local frac_length=${#frac_part}

    local pad_length=$(( frac_digits - frac_length - 1 ))
    local padding=""
    for ((i=0;i<pad_length;i++)); do
        padding="${padding}0"
    done

    local frac_padded="${frac_part}${padding}"
    frac_padded=${frac_padded#0*}

    local sign=${x:0:1}

    local res=0
    if [ "$sign" == "-" ]
    then
        res=$(( int_part * scale - frac_padded ))
    else
        res=$(( int_part * scale + frac_padded ))
    fi

    ret=$res
}

# Converts from fixed point to normal representation
# Doesn't really need to be fast as we only use it for debugging
from_fp() {
    local x=$1
    local int_part=$(( x / scale ))
    if [ $int_part -eq 0 ]
    then
        if [ $x -gt 0 ] || [ $x -eq 0 ]
        then
            x=$((x + scale))
        else
            int_part="-0"
            x=$((x - scale))
        fi
    fi

    # Can't just do x % scale, because this does not preserve leading zeroes
    local x_length=${#x}
    local decimal_point_pos=$((x_length - frac_digits + 1))
    local fract_part=${x:$decimal_point_pos:$frac_digits}
    ret=${int_part}.${fract_part}
}

vec3_print() {
    local -a v=("${!1}")
    from_fp "${v[0]}"; v[0]=$ret
    from_fp "${v[1]}"; v[1]=$ret
    from_fp "${v[2]}"; v[2]=$ret
    echo "{ ${v[0]}, ${v[1]}, ${v[2]} }"
}

print() {
    local ret
    from_fp "$1"
    echo "$1"
}

to_fp 1.5; three_halves=$ret

inv_sqrt() {
    sqrt "$1"
    div "$scale" "$ret"

    # if ((x<0)); then
    #     fatal "arg passed to inv sqrt x was negative ${x}"
    # fi
    # div_by_2 "$x"; local x2=$ret
    # div $scale $x; local guess=$ret
    # for i in {0..4}; do
    #     mul $guess $guess
    #     mul $ret $x2
    #     sub $three_halves $ret
    #     mul $ret $guess
    #     guess=$ret
    # done
    # ret=$guess
}

clamp_0_1() {
  ((ret = $1 > scale ? scale : $1 < 0 ? 0 : $1, 1))
}

source ./vec_math.sh
