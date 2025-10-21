import { deployContract } from "./utils";

// An example of a basic deploy script
// It will deploy a Greeter contract to selected network
// as well as verify it on Block Explorer if possible for the network
export default async function () {
  const contractArtifactName = "ERC20V2Claim";
  const constructorArguments = ["0x45656c02Aae856443717C34159870b90D1288203", "0x2dED74483a067d8040E6c08a013007a929312e82"];
  await deployContract(contractArtifactName, constructorArguments);
}
