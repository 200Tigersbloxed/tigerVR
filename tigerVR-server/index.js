const users = require('./users.js')
const privatee = require('./private/private.js')
const tools = require('./tools.js')

const fs = require('fs')
const express = require('express')
const http = require('http')
const https = require('https')
const WebSocket = require('ws')
const url = require('url')
const bodyParser = require("body-parser");

const app = express()

const useHttps = true
const certKey = fs.readFileSync("private/key.key", 'utf8')
const cert = fs.readFileSync("private/cert.pem", 'utf8')

function message(success, response = {}){
    let msg = {}
    if(success)
        msg['result'] = 'Success'
    else
        msg['result'] = 'Failure'
    msg['response'] = response
    return JSON.stringify(msg)
}

app.get('/', (req, res) => {
    res.end(message(true, {['method']: "root"}))
})

app.get('/verify', (req, res) => {
    res.redirect("https://www.roblox.com/games/10283252122/tigerVR-Verification")
})

app.get('/api/v1/getUserTrackersInfo', (req, res) => {
    let username = req.query.username
    if(username){
        if(username.includes(',')){
            // Bulk
            let trackerResults = {}
            let usersList = username.split(',')
            tools.forEachPromise(usersList, function(user){
                return new Promise((callback, reject) => {
                    users.isUserConnected(user).then(userConnected => {
                        if(userConnected){
                            users.getExtraTracking(user).then(extraTracking => {
                                try{
                                    let trackers = extraTracking[0]
                                    let faceweights = extraTracking[1]
                                    let trackersConnected = tools.countArray(trackers)
                                    trackerResults[user] = {
                                        ['trackingExtended']: trackersConnected > 0,
                                        ['trackersConnected']: trackersConnected,
                                        ['Trackers']: trackers,
                                        ['FaceWeights']: faceweights
                                    }
                                    callback()
                                }
                                catch(e){
                                    console.error(e)
                                    callback()
                                }
                            })
                        }
                        else
                            callback()
                    })
                })
            }).then(() => {
                res.end(message(true, trackerResults))
            }).catch(e => {
                if(e) console.error(e); else console.error("Unknown Error during Bulk Promise");
                res.end(message(false, {['reason']: "Internal Server Error"}))
            })
        }
        else{
            // Single-User
            users.isUserConnected(username).then(userConnected => {
                if(userConnected){
                    users.getExtraTracking(username).then(extraTracking => {
                        try{
                            let trackers = extraTracking[0]
                            let trackersConnected = tools.countArray(trackers)
                            let faceweights = extraTracking[1]
                            res.end(message(true, {
                                ['trackingExtended']: trackersConnected > 0,
                                ['trackersConnected']: trackersConnected,
                                ['Trackers']: trackers,
                                ['FaceWeights']: faceweights
                            }))
                        }
                        catch(e){
                            console.error(e)
                            res.end(message(false, {['reason']: "Internal Server Error"}))
                        }
                    })
                }
                else
                    res.end(message(false, {['reason']: "User " + username + " is not connected!"}))
            })
        }
    }
    else
        res.end(message(false, {['reason']: "Parameter username cannot be null"}))
})

app.use(bodyParser.urlencoded({extended: true}))
app.use(bodyParser.json())

app.post(privatee.VbywYYhW25cPb5GNw5Qa3RI7pY838MSLjpjnL0n2W8D7UuUJFc(), (req, res) => {
    privatee.D6BO3jVO2r4LYdDrUQVG5V2JGs765hH0SPGHwNGj634fL3pn9K(req.body, message).then(resb => {
        res.end(resb)
    }).catch(err => {
        console.error("p1-e " + err)
        res.end(message(false, {['reason']: "Internal Server Error"}))
    })
})

http.createServer(app).listen(80, function(){
    let port = this.address().port
    console.log("HTTP Server listening on port " + port)
})

if(useHttps){
    https.createServer({
        key: certKey,
        cert: cert
    }, app).listen(443, function(){
        let port = this.address().port
        console.log("HTTPS Server listening on port " + port)
    })
}

const disablePings = false

let sockets = []
const wssServer = (useHttps === true) ? https.createServer({
    cert: cert,
    key: certKey
}) : http.createServer()
let wss = new WebSocket.Server({noServer: true})

wss.on('connection', function(socket){
    sockets.push(socket)

    let didPing = true
    let pingId

    let username
    let token
    let settings

    socket.on('message', msg => {
        let parsedMessage
        try{
            parsedMessage = JSON.parse(msg.toString())
            if(parsedMessage && parsedMessage.method){
                switch (parsedMessage.method){
                    case 'pong':
                        if(parsedMessage['pingId'] === pingId)
                            didPing = true
                        break
                    case 'addUser':
                        username = parsedMessage['username']
                        token = parsedMessage['token']
                        settings = users.DefaultSettings
                        if(parsedMessage.settings && parsedMessage.settings !== {})
                            settings = parsedMessage.settings
                        users.addUser(username, token, settings).then(res => {
                            socket.send(message(res, {['method']: 'addUserResponse',['userWasAdded']: res}))
                        })
                        break
                    case 'pushTrackers':
                        username = parsedMessage['username']
                        token = parsedMessage['token']
                        if(username && token)
                        {
                            if(parsedMessage['trackers'])
                                users.pushTrackers(username, token, parsedMessage['trackers'])
                            if(parsedMessage['faceweights'])
                                users.pushFaceWeights(username, token, parsedMessage['faceweights'])
                        }
                        break
                    default:
                        console.warn("Unknown method " + parsedMessage.method)
                        break
                }
            }
            else
                console.warn("parsedMessage or method was null! msg: " + msg)
        }
        catch (e){
            console.error('Failed to handle message ' + message)
        }
    })

    socket.on('close', function(){
        sockets = sockets.filter(s => s !== socket)
        if(username && token)
            users.removeUser(username, token)
    })

    // Ping-Pong
    if(!disablePings){
        setInterval(() => {
            if(didPing){
                pingId = tools.generatePassword(16)
                didPing = false
                socket.send(message(true, {
                    "method": "ping",
                    "pingId": pingId
                }))
            }
            else{
                // Kick for inactivity
                socket.terminate()
            }
        }, 30000)
    }
})

wssServer.on('upgrade', function upgrade(request, socket, head){
    const pathname = url.parse(request.url).pathname

    if (pathname === '/clientdata'){
        wss.handleUpgrade(request, socket, head, function done(ws) {
            wss.emit('connection', ws, request)
        })
    }
    else{
        socket.destroy();
    }
})
wssServer.listen(2096)