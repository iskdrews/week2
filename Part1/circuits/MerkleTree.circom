pragma circom 2.0.0;

// Refer to:
// https://github.com/peppersec/tornado-mixer/blob/master/circuits/merkleTree.circom
// https://github.com/appliedzkp/semaphore/blob/master/circuits/circom/semaphore-base.circom
// https://github.com/privacy-scaling-explorations/maci/tree/master/circuits/circom/trees

include "../node_modules/circomlib/circuits/mux1.circom";
include "./hasherPoseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    var totalLeaves = 2 ** n;

    var numLeafHashers = totalLeaves / 2;

    var numIntermediateHashers = numLeafHashers - 1;

    signal input leaves[totalLeaves];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    var numHashers = totalLeaves - 1;
    component hashers[numHashers];

    var i; 
    for (i = 0; i < numHashers; i++) {
        hashers[i] = HashLeftRight();
    }

    for (i = 0; i < numLeafHashers; i++) {
        hashers[i].left <== leaves[i*2];
        hashers[i].right <== leaves[i*2+1];
    }

    var k = 0;
    for (i=numLeafHashers; i<numLeafHashers + numIntermediateHashers; i++) {
        hashers[i].left <== hashers[k*2].hash;
        hashers[i].right <== hashers[k*2+1].hash;
        k++;
    }

    root <== hashers[numHashers - 1].hash;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n][1];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    component hashers[n];
    component mux[n];

    signal levelHashes[n + 1];
    levelHashes[0] <== leaf;

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    for (var i = 0; i < n; i++) {
        // Should be 0 or 1
        path_index[i] * (1 - path_index[i]) === 0;

        hashers[i] = HashLeftRight();
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== levelHashes[i];
        mux[i].c[0][1] <== path_elements[i][0];

        mux[i].c[1][0] <== path_elements[i][0];
        mux[i].c[1][1] <== levelHashes[i];

        mux[i].s <== path_index[i];
        hashers[i].left <== mux[i].out[0];
        hashers[i].right <== mux[i].out[1];

        levelHashes[i + 1] <== hashers[i].hash;
    }

    root <== levelHashes[n];
}
