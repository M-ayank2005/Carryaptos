const Reciever_Post = require("../models/Reciever_Post.jsx");
// const Sender_Post = require("../models/Sender_Post.jsx");




exports.createRecieverPost=async(req,res)=>{


    try {
        const token=req.cookies.token||req.body.token;

        if(!token){
            return res.status(401).json({
                success:false,
                 message:'token is missing ,Please Login !!!'
            })
        }
    var source=req.body.source
    var destination=req.body.destination
    var reciever=req.body.reciever
    var pnr=req.body.pnr
    var seatNumber=req.body.seatNumber
    var email=req.body.email
     
        // const tokenObj=jwt.verify(token,process.env.JWT_SECRET);


        if(!source||!destination||!reciever||!pnr||pnr.trim()==''||source.trim()==''||destination.trim()==''||!seatNumber||seatNumber.trim()==''){
            // console.log('hiiii')
            return res.status(401).json({
                success:false,
                message:'All fields are mandatory'
            })
        }
        

        if(await Reciever_Post.findOne({email:`${email}`}) ){
            return  res.status(401).json({
                success:false,
                message:"You can only create one post per day"
            })
        }


         await Reciever_Post.create({
            email:email,
            source:source,
            pnr:pnr,
            seatNumber:seatNumber,
            destination:destination,
            // reciever:reciever
             
        
        });
        return res.status(200).json({
            success:true,
            message:'Post created successfully !!!'
        })


    } catch (error) {
        console.log('createPost fata hai ----> ',error)
        return res.status(400).json({
    
            success:false,
            message:'something went wrong while creating Post',
            error:error.message
        })
    }


}