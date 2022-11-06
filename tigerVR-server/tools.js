exports.countArray = function(array){
    let i = 0
    array.forEach(function(entry){
        i = i + 1
    })
    return i
}

// https://stackoverflow.com/a/1497512/12968919
exports.generatePassword = function(length) {
    let charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
        retVal = ""
    for (let i = 0, n = charset.length; i < length; ++i) {
        retVal += charset.charAt(Math.floor(Math.random() * n));
    }
    return retVal;
}

// https://stackoverflow.com/a/41791149/12968919
/**
 *
 * @param items An array of items.
 * @param fn A function that accepts an item from the array and returns a promise.
 * @returns {Promise}
 */
exports.forEachPromise = function(items, fn) {
    return items.reduce(function (promise, item) {
        return promise.then(function () {
            return fn(item);
        });
    }, Promise.resolve());
}