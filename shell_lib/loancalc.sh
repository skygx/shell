#!/bin/bash
# vim:sw=4:ts=4:et
<<INFO
    @Project :   shell
    @File    :   loancalc.sh
    @Contact :   guoxin_well@126.com
    @License :   (C)Copyright 2022-2023, xguo

@Modify Time            @Author    @Version    @Desciption
------------------      -------    --------    -----------
2022/11/23 下午 3:10         hello      1.0         None
INFO

. ./library.sh

if [ $# -ne 3 ]; then
    echo "Usage: $0 principal interest loan-duration-years" >&2
    exit 1
fi

P=$1 I=$2 L=$3
J="$(scriptbc -p 8 $I / \( 12 \* 100 \) )"
N="$(( $L * 12))"
M="$(scriptbc -p 8 $P \* \( $J / \(1 - \(1 + $J\) \^ -$N\) \) )"
dollars="$(echo $M | cut -d. -f1)"
cents="$(echo $M | cut -d. -f2 |cut -c1-2)"

cat <<EOF
A $L-year loan at $I% interest with a principal amount of $(nicenumber $P 1 )
results in a payment of \$$dollars.$cents each month for the duration of
the loan ($N payments).
EOF

exit 0
