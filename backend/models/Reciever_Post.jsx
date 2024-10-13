const mongoose=require('mongoose');
// const mailSender=require('../utils/mailSender.jsx')
const postSchema=new mongoose.Schema({
    
     
    email:{
        type:String,
        trim:true,
        required:true   
    },
    source:{
        type:String,
        trim:true,
        required:true   
    },
    destination:{
        type:String,
        trim:true,
        required:true   
    },
    
    date:{
        type:Date,
        required:true
    },

    createdAt:{
        type:Date,
        required:true,
        default:Date.now()
    },
    status:{
        type:Boolean,
        default:false,
        required:true,
    },
    expiresAt:{
        type:Date,
        required:true,
       default:new Date(new Date(new Date()).getTime()+(24+7-new Date((Date.now())).getHours())*60*60*1000 -(new Date((Date.now())).getMinutes()*60*1000)).getTime()
        // default:new Date(Date.now()).getTime()
            },

     pnr:{
                type:String,
             required:true,
            },
     seatNumber:{
                type:String,
             required:false,
            },
    
     reciever:{
        type:mongoose.Schema.Types.ObjectId,
            ref:'User'
     },
    
    
});
 

module.exports=mongoose.model('Reciever_Post',postSchema);