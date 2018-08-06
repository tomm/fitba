var _user$project$Native_Notification = function() {

    var NotificationAPI = null;
    if (typeof Notification !== "undefined") {
        NotificationAPI = Notification;
    }

    var Task = _elm_lang$core$Native_Scheduler;

    var status = {
        Denied: "denied",
        Granted: "granted",
        Default: "default"
    }

    function permission() {
        switch (NotificationAPI.permission){
        case status.Denied:
            return {ctor: "Denied"}
        case status.Granted:
            return {ctor: "Granted"}
        default:
            return {ctor: "Default"}

        }
    }

    function isObject(val) {
        return Object.prototype.toString.call(val)
                     .replace(/\]/, "")
                     .split(" ")[1] === "Object";
    }

    function prepareOptions(data) {
        Object.keys(data).map(function(key){
            if (isObject(data[key])){
                switch(data[key].ctor) {
                case "Nothing":
                    return data[key] = undefined;
                case "Just":
                    if (key === "vibrate") {
                        return data[key] = _elm_lang$core$Native_List.toArray(data[key]._0)
                    }
                    return data[key] = data[key]._0;
                }
            }
        });
        return data;
    }

    return {

        getPermission: Task.nativeBinding(function(callback) {
	        if (NotificationAPI) {
                callback(Task.succeed(permission(NotificationAPI.permission)));
            }
        }),

        requestPermission: Task.nativeBinding(function(callback) {
            if (NotificationAPI) {
                NotificationAPI.requestPermission(function(result) {
                    callback(Task.succeed(permission()));
               });
            }
        }),

        spawnNotification: function(data) {
            if (NotificationAPI) {
                return Task.nativeBinding(function(callback) {
                    switch (NotificationAPI.permission) {
                        case status.Granted:
                            new NotificationAPI(data.title, prepareOptions(data.options));
                            return callback(Task.succeed(_elm_lang$core$Native_Utils.Tuple0));
                        case status.Denied:
                            return callback(Task.fail({ctor: "PermissionDenied"}))
                        case status.Default:
                            return callback(Task.fail({ctor: "UserNotAsked"}))

                    }
                });
            } else {
                return Task.nativeBinding(function(callback) {});
            }
        }
    }
}();
