import * as SDK from "../generated/sdk";
import { GraphQLClient } from "graphql-request";

const client = new GraphQLClient("http://localhost:3333/graphql");

export const sdk = () => {
    return SDK.getSdk(client); 
}

export default SDK