
let scale="100000000"
let frac_digits=${#scale}

add() {
    local a=$1
    local b=$2
    echo $((a + b))
}

sub() {
    local a=$1
    local b=$2
    echo $((a - b))
}

mul() {
    local a=$1
    local b=$2
    local res=$((a * b / scale))

    if [ $res -lt 0 ] && [ $a -gt 0 ] && [ $b -gt 0 ]
    then
        log "OVERFLOW DETECTED: ${a} x ${b} = ${res}"
    fi

    echo $res
}

div() {
    local a=$1
    local b=$2
    echo $((a * scale / b))
}

div_by_2() {
    local a=$1
    echo $((a >> 1))
}


mul_by_2() {
    local a=$1
    echo $((a << 1))
}

truncate() {
    local a=$1
    echo $((a / scale))
}

abs() {
    local x=$1
    if [ $x -lt 0 ]
    then
        echo $(( -x ))
    else
        echo $x
    fi
}


sqrt() {
    local x=$1
    if [ "$x" -lt 0 ]
    then
        fatal "arg passed to sqrt x was negative: ${x}"
        # TODO mul can exceed the precision needed so certain dot products get
        # weird
        # x=$(abs $x)
        # echo 0
        # return
    fi

    local guess=$(div_by_2 $x)
    for i in {0..5}
    do
        if [ $guess -eq 0 ]
        then
            guess=0
            break
        fi

        local tmp=$(div $x $guess)
        tmp=$(add $tmp $guess)
        guess=$(div_by_2 $tmp)
    done
    echo $guess
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

    echo $res
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
    echo "${int_part}.${fract_part}"
}

vec3_print() {
    local v=("${!1}")
    echo "{ $(from_fp ${v[0]}), $(from_fp ${v[1]}), $(from_fp ${v[2]}) }"
}

print() {
    from_fp $1
}

three_halves=$(to_fp 1.5)

inv_sqrt() {
    local x=$1
    div $scale $(sqrt $x)
    # if [ "$x" -lt 0 ]
    # then
    #     fatal "arg passed to inv sqrt x was negative ${x}"
    # fi

    # local x2=$(div_by_2 $x)
    # local guess=$(div $scale $x)

    # for i in {0..4}
    # do
    #     local tmp=$(mul $guess $guess)
    #     tmp=$(mul $tmp $x2)
    #     tmp=$(sub $three_halves $tmp)
    #     guess=$(mul $tmp $guess)
    # done

    # echo $guess
}

clamp_0_1() {
    local x=$1
    if [ $x -gt $scale ]
    then
        echo $scale
    else
        if [ $x -lt 0 ]
        then
            echo 0
        else
            echo $x
        fi
    fi
}

source ./vec_math.sh
