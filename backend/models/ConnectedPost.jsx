const mongoose=require('mongoose');
const mailSender=require('../utils/mailSender.jsx')
const postSchema=new mongoose.Schema({
    
     
   source:{
    type:mongoose.Schema.Types.ObjectId,
            ref:'Sender_Post'
   },

   destination:{
     type:mongoose.Schema.Types.ObjectId,
            ref:'Reciever_Post'
   }
     
    
});
 

module.exports=mongoose.model('Post',postSchema);