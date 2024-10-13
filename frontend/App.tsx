import { useState } from "react";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { AptosClient } from "aptos";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Header } from "@/components/Header";
import { WalletDetails } from "@/components/WalletDetails";

const NODE_URL = "https://fullnode.testnet.aptoslabs.com";
const aptosClient = new AptosClient(NODE_URL);

const CONTRACT_ADDRESS = "0x<your_contract_address>";
const MODULE_NAME = "TransportContract";
const CREATE_ORDER_FUNCTION = "create_order";
const AGREE_FUNCTION = "agree_order";
const CONFIRM_DELIVERY_FUNCTION = "confirm_delivery";
const FINALIZE_ORDER_FUNCTION = "finalize_order";

function App() {
  const { connected, signAndSubmitTransaction, account } = useWallet();
  const [orderCreated, setOrderCreated] = useState(false);
  const [carrierAgreed, setCarrierAgreed] = useState(false);
  const [senderAgreed, setSenderAgreed] = useState(false);
  const [deliveryConfirmed, setDeliveryConfirmed] = useState(false);
  const [goodsValue, setGoodsValue] = useState("");
  const [serviceFee, setServiceFee] = useState("");

  // Handlers
  const createOrder = async () => {
    if (!connected || !account) {
      alert("Please connect your wallet");
      return;
    }

    try {
      const payload = {
        type: "entry_function_payload",
        function: `${CONTRACT_ADDRESS}::${MODULE_NAME}::${CREATE_ORDER_FUNCTION}`,
        arguments: [goodsValue, serviceFee],
        type_arguments: [],
      };

      const transaction = {
        sender: account.address,
        payload: payload,
        // Remove the `data` property entirely if it's not required
      };

      const response = await signAndSubmitTransaction(transaction);
      await aptosClient.waitForTransaction(response.hash);

      setOrderCreated(true);
      alert("Order created successfully!");
    } catch (err) {
      console.error("Failed to create order:", err);
    }
  };

  const agreeOrder = async (role:any) => {
    if (!connected || !account) {
      alert("Please connect your wallet");
      return;
    }

    try {
      const payload = {
        type: "entry_function_payload",
        function: `${CONTRACT_ADDRESS}::${MODULE_NAME}::${AGREE_FUNCTION}`,
        arguments: [role], // 0 for carrier, 1 for sender
        type_arguments: [],
      };

      const transaction = {
        sender: account.address,
        payload: payload,
        // Remove the `data` property entirely if it's not required
      };

      const response = await signAndSubmitTransaction(transaction);
      await aptosClient.waitForTransaction(response.hash);

      role === 0 ? setCarrierAgreed(true) : setSenderAgreed(true);
      alert(role === 0 ? "Carrier agreed!" : "Sender agreed!");
    } catch (err) {
      console.error("Failed to agree order:", err);
    }
  };

  const confirmDelivery = async () => {
    if (!connected || !account) {
      alert("Please connect your wallet");
      return;
    }

    if (!carrierAgreed || !senderAgreed) {
      alert("Both parties need to agree before confirming delivery.");
      return;
    }

    try {
      const payload = {
        type: "entry_function_payload",
        function: `${CONTRACT_ADDRESS}::${MODULE_NAME}::${CONFIRM_DELIVERY_FUNCTION}`,
        arguments: [],
        type_arguments: [],
      };

      const transaction = {
        sender: account.address,
        payload: payload,
        // Remove the `data` property entirely if it's not required
      };

      const response = await signAndSubmitTransaction(transaction);
      await aptosClient.waitForTransaction(response.hash);

      setDeliveryConfirmed(true);
      alert("Delivery confirmed by the sender!");
    } catch (err) {
      console.error("Failed to confirm delivery:", err);
    }
  };

  const finalizeOrder = async () => {
    if (!connected || !account) {
      alert("Please connect your wallet");
      return;
    }

    if (!deliveryConfirmed) {
      alert("Delivery must be confirmed before finalizing the order.");
      return;
    }

    try {
      const payload = {
        type: "entry_function_payload",
        function: `${CONTRACT_ADDRESS}::${MODULE_NAME}::${FINALIZE_ORDER_FUNCTION}`,
        arguments: [],
        type_arguments: [],
      };

      const transaction = {
        sender: account.address,
        payload: payload,
        // Remove the `data` property entirely if it's not required
      };

      const response = await signAndSubmitTransaction(transaction);
      await aptosClient.waitForTransaction(response.hash);

      alert("Order finalized! Funds have been transferred to the carrier.");
    } catch (err) {
      console.error("Failed to finalize order:", err);
    }
  };

  return (
    <>
      <Header />
      <div className="flex items-center justify-center flex-col p-4">
        {connected ? (
          <Card>
            <CardContent className="flex flex-col gap-6 pt-6">
              <WalletDetails />
              <div className="flex flex-col gap-4">
                <h2 className="text-xl font-semibold">Create an Order</h2>
                <input
                  type="text"
                  placeholder="Goods Value (APT)"
                  value={goodsValue}
                  onChange={(e) => setGoodsValue(e.target.value)}
                  className="border rounded p-2"
                />
                <input
                  type="text"
                  placeholder="Service Fee (APT)"
                  value={serviceFee}
                  onChange={(e) => setServiceFee(e.target.value)}
                  className="border rounded p-2"
                />
                <button
                  onClick={createOrder}
                  className="bg-blue-500 text-white p-2 rounded"
                  disabled={orderCreated}
                >
                  {orderCreated ? "Order Created" : "Create Order"}
                </button>
              </div>

              {orderCreated && (
                <div className="flex flex-col gap-4">
                  <h2 className="text-xl font-semibold">Agreement Section</h2>
                  <button
                    onClick={() => agreeOrder(0)}
                    className="bg-green-500 text-white p-2 rounded"
                    disabled={carrierAgreed}
                  >
                    {carrierAgreed ? "Carrier Agreed" : "Carrier Agree"}
                  </button>
                  <button
                    onClick={() => agreeOrder(1)}
                    className="bg-green-500 text-white p-2 rounded"
                    disabled={senderAgreed}
                  >
                    {senderAgreed ? "Sender Agreed" : "Sender Agree"}
                  </button>
                </div>
              )}

              {carrierAgreed && senderAgreed && (
                <div className="flex flex-col gap-4">
                  <h2 className="text-xl font-semibold">Delivery Confirmation</h2>
                  <button
                    onClick={confirmDelivery}
                    className="bg-yellow-500 text-white p-2 rounded"
                    disabled={deliveryConfirmed}
                  >
                    {deliveryConfirmed ? "Delivery Confirmed" : "Confirm Delivery"}
                  </button>
                </div>
              )}

              {deliveryConfirmed && (
                <div className="flex flex-col gap-4">
                  <h2 className="text-xl font-semibold">Finalize Order</h2>
                  <button
                    onClick={finalizeOrder}
                    className="bg-red-500 text-white p-2 rounded"
                  >
                    Finalize Order
                  </button>
                </div>
              )}
            </CardContent>
          </Card>
        ) : (
          <CardHeader>
            <CardTitle className="text-blue-400">
              Please connect your wallet to proceed
            </CardTitle>
          </CardHeader>
        )}
      </div>
    </>
  );
}

export default App;
