const mongoose=require('mongoose');
const mailSender=require('../utils/mailSender.jsx')

const userSchema=new mongoose.Schema({
    firstName:{
        type:String,
        trim:true,
        required:true
    },
    lastName:{
        type:String,
        trim:true,
        required:true
    },
    email:{
        type:String,
        trim:true,
        required:true
    },
    phoneNo:{
        type:String,
        trim:true,
        required:true
    },
   
    password:{
        type:String,
        trim:true,
        required:true
    },
    
    // posts:[
    //     {
    //         type:mongoose.Schema.Types.ObjectId,
    //         ref:'Post'
    //     }
    // ],
   
    address:{
        type:String,
    
        trim:true,
        default:''
    },
    

})

userSchema.post('save',async function(){
    try {

        const  mailResponse=await mailSender(this.email,'ACCOUNT CREATED SUCCESSFULLY !!! @Community Cares',`Dear ${this.firstName} <br/> Welcome to Community Cares ! We're thrilled to have you join our community and embark on this exciting journey with us`);
        console.log('email for account creation sent successfully',mailResponse);
    
        
    } catch (error) {
        console.log('error occured while sending account creation mail : ',error);
        throw error;
    }
})

module.exports=mongoose.model('User',userSchema);