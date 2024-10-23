import { afterAll, describe, test, expect } from "bun:test";
import { buildBn128 } from "ffjavascript";
import fs from "fs";
import { groth16 } from "snarkjs";
import type { PublicSignals, Groth16Proof } from "snarkjs";

let curve = await buildBn128(true);
globalThis.curve_bn128 = curve;

const CIRCUIT_NAME = "CheckMult";
const ZKEY_PATH = `./build/${CIRCUIT_NAME}/${CIRCUIT_NAME}.zkey`;
const WASM_PATH = `./build/${CIRCUIT_NAME}/${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm`;
const VKEY_PATH = `./build/${CIRCUIT_NAME}/${CIRCUIT_NAME}_vkey.json`;

const verify = async (proof: Groth16Proof, publicSignals: PublicSignals) => {
  let fileData = fs.readFileSync(VKEY_PATH);
  const vKey = JSON.parse(String(fileData));
  return await groth16.verify(vKey, publicSignals, proof);
};

afterAll(async () => {
  // cleanup curves
  await globalThis.curve_bn128?.terminate();
});

describe("Test Mult", () => {
  test("Mock generate data", async () => {
    const inputData = {
      a: 10,
      b: 12,
      ab: 120,
    };

    const { publicSignals, proof } = await groth16.fullProve(
      inputData,
      WASM_PATH,
      ZKEY_PATH,
    );

    expect(publicSignals[0]).toEqual("1");
    expect(publicSignals[1]).toEqual("120");

    let verificationResp = await verify(proof, publicSignals);

    expect(verificationResp).toBe(true);
  }, 60000);
});
