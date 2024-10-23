pragma circom 2.2.0;

template IsZero() {
    signal input in;
    signal output out;
    signal inv;
    inv <-- in!=0 ? 1/in : 0;
    out <== -in*inv +1;
    in*out === 0;
}

template IsEqual() {
    signal input in[2];
    signal output out;
    component isz = IsZero();
    in[1] - in[0] ==> isz.in;
    isz.out ==> out;
}

template CheckMult() {
    signal input a;
    signal input b;
    signal input ab;
    signal output out;

    component eq = IsEqual();
    eq.in[0] <== a * b;
    eq.in[1] <== ab;
    eq.out ==> out;
}

component main { public [ab] } = CheckMult();

/* INPUT = {
    "a": "5",
    "b": "77",
    "ab": "265"
} */
