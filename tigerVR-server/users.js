let Users = []
let VerifiedUsers = []

exports.DefaultSettings = Object.freeze({})

exports.isUserConnected = function(username){
    return new Promise((callback, reject) => {
        Object.keys(Users).forEach(function(key){
            if(key === username)
                callback(true)
        })
        callback(false)
    })
}

exports.isUserVerified = function(username){
    return new Promise((callback, reject) => {
        Object.keys(VerifiedUsers).forEach(function(key){
            if(key === username)
                callback(true)
        })
        callback(false)
    })
}

exports.isTokenValid = function(username, token){
    return new Promise((callback, reject) => {
        let i = 0
        for (const [key, value] of Object.entries(VerifiedUsers)) {
            i = i + 1
            if (key === username)
                if (value.Token === token)
                    callback(true)
        }
        callback(false)
    })
}

exports.addVerifiedUser = function(username, token){
    VerifiedUsers[username] = {
        ['Username']: username,
        ['Token']: token
    }
}

exports.removeVerifiedUser = function(username){
    VerifiedUsers = VerifiedUsers.filter(user => user.Username !== username)
}

exports.addUser = function(username, token, settings){
    return new Promise((callback, reject) => {
        username = username.toString()
        exports.isUserConnected(username).then(userConnected => {
            if(!userConnected){
                exports.isTokenValid(username, token).then(tokenValid => {
                    if(tokenValid){
                        Users[username] = {
                            ['Username']: username,
                            ['Settings']: settings,
                            ['Trackers']: [],
                            ['FaceWeights']: []
                        }
                        console.log('[Users]: Added user ' + username)
                        callback(true)
                    }
                    else{
                        console.warn('[Users] User [' + username + '] token is invalid!')
                        callback(false)
                    }
                })
            }
            else{
                console.warn('[Users] User ' + username + ' is already connected!')
                exports.removeUser(username, token)
                callback(false)
            }
        })
    })
}

exports.removeUser = function(username, token){
    exports.isTokenValid(username, token).then(tokenValid => {
        if(tokenValid){
            Users = Users.filter(user => user.Username !== username)
            console.log('[Users] User ' + username + " removed!")
        }
    })
}

exports.getExtraTracking = function(username){
    return new Promise((callback, reject) => {
        exports.isUserConnected(username).then(userConnected => {
            if(userConnected){
                callback([Users[username].Trackers, Users[username].FaceWeights])
            }
            else{
                console.warn('[Users] User ' + username + ' is not connected!')
                callback([])
            }
        })
    })
}

function createTracker(tracker){
    let t = {}
    if (tracker["Name"] != null)
        t["Name"] = tracker["Name"]
    if(tracker["Position"] != null){
        t["Position"] = {"X": 0.0, "Y": 0.0, "Z": 0.0}
        if(tracker["Position"]["X"] != null)
            t["Position"]["X"] = tracker["Position"]["X"]
        if(tracker["Position"]["Y"] != null)
            t["Position"]["Y"] = tracker["Position"]["Y"]
        if(tracker["Position"]["Z"] != null)
            t["Position"]["Z"] = tracker["Position"]["Z"]
    }
    if(tracker["Rotation"] != null){
        t["Rotation"] = {"X": 0.0, "Y": 0.0, "Z": 0.0, "W": 0.0}
        if(tracker["Rotation"]["X"] != null)
            t["Rotation"]["X"] = tracker["Rotation"]["X"]
        if(tracker["Rotation"]["Y"] != null)
            t["Rotation"]["Y"] = tracker["Rotation"]["Y"]
        if(tracker["Rotation"]["Z"] != null)
            t["Rotation"]["Z"] = tracker["Rotation"]["Z"]
        if(tracker["Rotation"]["W"] != null)
            t["Rotation"]["W"] = tracker["Rotation"]["W"]
    }
    return t
}

exports.pushTrackers = function(username, token, trackers){
    return new Promise((callback, reject) => {
        exports.isUserConnected(username).then(userConnected => {
            if(userConnected){
                exports.isTokenValid(username, token).then(tokenValid => {
                    if(tokenValid){
                        try{
                            let arr = []
                            for(let i = 0; i < trackers.length; i++){
                                let t = trackers[i]
                                let tracker = createTracker(t)
                                arr.push(tracker)
                            }
                            Users[username].Trackers = arr
                            callback(true)
                        }
                        catch (e){
                            console.log("Failed to parse Trackers " + trackers + " : " + e)
                            callback(false)
                        }
                    }
                    else{
                        console.error('[Users] User ' + username + ' provided the wrong token! Fake Token: ' + token)
                        callback(false)
                    }
                })
            }
            else{
                console.warn('[Users] User ' + username + ' is not connected!')
                callback(false)
            }
        })
    })
}

exports.pushFaceWeights = function(username, token, faceWeights){
    return new Promise((callback, reject) => {
        exports.isUserConnected(username).then(userConnected => {
            if(userConnected){
                exports.isTokenValid(username, token).then(tokenValid => {
                    if(tokenValid){
                        try{
                            let fw = []
                            for(let i = 0; i < faceWeights.length; i++){
                                let faceWeight = faceWeights[i]
                                let b = true
                                let o = {}
                                if(faceWeight["Name"] != null)
                                    o["Name"] = faceWeight["Name"]
                                else
                                    b = false
                                if(faceWeight["Value"] != null)
                                    o["Value"] = faceWeight["Value"]
                                else
                                    b = false
                                if(b)
                                    fw.push(o)
                            }
                            Users[username].FaceWeights = fw
                            callback(true)
                        }
                        catch (e) {
                            console.log("Failed to parse FaceWeights " + faceWeights + " : " + e)
                            callback(false)
                        }
                    }
                    else{
                        console.error('[Users] User ' + username + ' provided the wrong token! Fake Token: ' + token)
                        callback(false)
                    }
                })
            }
            else{
                console.warn('[Users] User ' + username + ' is not connected!')
                callback(false)
            }
        })
    })
}