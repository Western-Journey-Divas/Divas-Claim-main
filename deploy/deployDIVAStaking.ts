import { deployContract } from "./utils";

// An example of a basic deploy script
// It will deploy a Greeter contract to selected network
// as well as verify it on Block Explorer if possible for the network
export default async function () {
  const contractArtifactName = "DIVAStaking";
  const constructorArguments = ["0x45656c02Aae856443717C34159870b90D1288203"];
  await deployContract(contractArtifactName, constructorArguments);
}
