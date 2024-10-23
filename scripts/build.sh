#!/bin/bash

PHASE1=./build/powersOfTau28_hez_final_20.ptau
CIRCUIT_NAME=$1
BUILD_DIR=./build/$1

if [ -f "$PHASE1" ]; then
    echo "Found Phase 1 ptau file"
else
    echo "No Phase 1 ptau file found. Exiting..."
    exit 1
fi

if [ ! -d "$BUILD_DIR" ]; then
    echo "No build directory found. Creating build directory..."
    mkdir -p "$BUILD_DIR"
fi

echo "\\n**** COMPILING CIRCUIT ****"
start=`date +%s`
set -x
circom "./circuits/$CIRCUIT_NAME".circom --r1cs --wasm --c --output "$BUILD_DIR"
{ set +x; } 2>/dev/null
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\\n**** GENERATING ZKEY 0 ****"
start=`date +%s`
npx snarkjs groth16 setup "$BUILD_DIR"/"$CIRCUIT_NAME".r1cs "$PHASE1" "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\\n**** GENERATING FINAL ZKEY ****"
start=`date +%s`
NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs zkey beacon "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey "$BUILD_DIR"/"$CIRCUIT_NAME".zkey 12FE2EC467BD428DD0E966A6287DE2AF8DE09C2C5C0AD902B2C666B0895ABB75 10 -n="Final Beacon phase2"
rm "$BUILD_DIR"/"$CIRCUIT_NAME"_0.zkey
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\\n**** GENERATING VERIFICATION KEY ****"
start=`date +%s`
NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs zkey export verificationkey  "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/${CIRCUIT_NAME}_vkey.json
end=`date +%s`
echo "DONE ($((end-start))s)"

echo "\\n**** GENERATING SOLIDITY VERIFIER ****"
start=`date +%s`
NODE_OPTIONS="--max-old-space-size=56000" npx snarkjs zkey export solidityverifier  "$BUILD_DIR"/"$CIRCUIT_NAME".zkey "$BUILD_DIR"/${CIRCUIT_NAME}Verifier.sol
end=`date +%s`
echo "DONE ($((end-start))s)"

if command -v forge &> /dev/null
then
    echo "\\n**** SOLIDITY VERIFIER DETAILS ****"
    forge build --contracts "$BUILD_DIR"/${CIRCUIT_NAME}Verifier.sol --sizes --optimizer-runs 999 --via-ir --use 0.8.28 --evm-version cancun
    echo "Verifier Generated"
fi

echo "\\n**** GENERATING RUST VERIFIER ****"
node ./scripts/rustVerifier.cjs "$BUILD_DIR"/${CIRCUIT_NAME}_vkey.json ./"$BUILD_DIR"/${CIRCUIT_NAME}_vkey.rs

echo "\\n**** GENERATING VYPER VERIFIER ****"
node ./scripts/genVerifier.cjs vyper ${CIRCUIT_NAME}

echo "\\n**** GENERATING FE VERIFIER ****"
node ./scripts/genVerifier.cjs fe ${CIRCUIT_NAME}
