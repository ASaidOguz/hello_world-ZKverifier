## SIMPLE ZK verifier --> Hello world 

This is just tests code for generating verification and calldata and compare the hashed binaries to understand the similarities.

- calldata-app.json ---> this calldata procured from garaga app from [scaffold-garaga](https://github.com/keep-starknet-strange/scaffold-garaga) , added simple download file function to get.
```

export function downloadCalldata(calldata: bigint[], filename: string = 'calldata.json') {
    const calldataAsStrings = calldata.map(e => e.toString());
    const blob = new Blob([JSON.stringify(calldataAsStrings, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    link.click();

    URL.revokeObjectURL(url);
}
```

and import,add this function inside start_process function of app.tsx ![as shown](./images/Ekran%20Alıntısı.PNG) 

- calldata.json can be procured direclty from generate_vk-calldata.js

```
node generate_vk-calldata.js
```

and then compare both jsons if they'r identical by 

```
compare_binary.bash calldata.json calldata-app.json
```

-> dont forget to make the bash script as executeable before comparing.

```
chmod +x compare_binary.bash 
```
- Now we can use deployed verifier contract to verifiy our proofs.
Just start local devnet by 
```
make start_dev
```

and then declare and deploy the verifier.

```
make declare_local_UltraStarknetHonkVerifier
```

```
make deploy_local_UltraStarknetHonkVerifier
```

and then simply run 

```
make verify_proof CONTRACT_ADDRESS=$(Contract address from deployment)
```

if the proof is valid it will return public inputs of the circuit.


one important part is both proof should be same inputs -> so in garaga app it should be x:1 y:2 
