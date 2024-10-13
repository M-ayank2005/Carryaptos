const express=require('express');
const router=express.Router();





 const {createRecieverPost}=require('../controller/Reciever.jsx');
const { createSenderPost } = require('../controller/Sender.jsx');
 

  

router.post('/recieverPost',createRecieverPost);
router.post('/senderPost',createSenderPost);
 
 



module.exports=router;