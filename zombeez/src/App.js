import React, {useEffect, useState} from 'react';
import {
  ChakraProvider,
  Box,
  Text,
  Link,
  VStack,
  Code,
  Grid,
  Image,
  Button
} from '@chakra-ui/react';
import { useDispatch, useSelector } from "react-redux";
import { connect } from "./redux/blockchain/blockchainActions";
import { fetchData } from "./redux/data/dataActions";
import '@fontsource/arbutus'
import theme from "./theme"
import hg from './assets/hive_cropped.gif'

function App() {
  const dispatch = useDispatch();
  const blockchain = useSelector((state) => state.blockchain);
  const data = useSelector((state) => state.data);
  const [feedback, setFeedback] = useState(".025 Mint Price");
  const [claimingNft, setClaimingNft] = useState(false);

  const claimNFTs = (_amount) => {
    if (_amount <= 0) {
      return;
    }
    setFeedback("Minting your Zombeez...");
    setClaimingNft(true);
    blockchain.smartContract.methods
      .mintNFTs(_amount)
      .send({
        gasLimit: (285000 * _amount).toString(),
        to: "0x151f56881146f5bda180f38111e89b8e28b0b954",
        from: blockchain.account,
        value: blockchain.web3.utils.toWei(
          (0.025 * _amount).toString(),
          "ether"
        ),
      })
      .once("error", (err) => {
        console.log(err);
        setFeedback(
          "Sorry, something went wrong please try again later or contact support"
        );
        setClaimingNft(false);
      })
      .then((receipt) => {
        setFeedback("You now own a Zombee! go visit Opensea.io to view it.");
        setClaimingNft(false);
        dispatch(fetchData(blockchain.account));
      });
  };

  const getData = () => {
    if (blockchain.account !== "" && blockchain.smartContract !== null) {
      dispatch(fetchData(blockchain.account));
    }
  };

  useEffect(() => {
    getData();
  }, [blockchain.account]);

  return (
    <ChakraProvider theme={theme}>
      <Box textAlign="center" fontSize="l" backgroundColor="black">
        <Grid minH="100vh" p={3}>
          <VStack spacing={50}>
            <Image src={hg} htmlHeight="600" htmlWidth="700"/>
            {blockchain.account === "" ||
             blockchain.smartContract === null ? (
              <>
            <Button width="20%" 
              onClick={(e) => {
                e.preventDefault();
                dispatch(connect());
                getData();
              }}
              >Connect to MetaMask</Button>
              </> 
              ) : (
                <>
              <Button width="20%" 
                disabled={claimingNft ? 1 : 0}
                onClick={(e) => {
                  e.preventDefault();
                  claimNFTs(1);
                  getData();
                }}
              >Mint 1 Zombee for .03 ETH</Button>
                </>
              )}
          <Text>Welcome to Zombeez, a collection of 8335 pixelated spooky beez!</Text>
          </VStack>
        </Grid>
      </Box>
    </ChakraProvider>
  );
}

export default App;
