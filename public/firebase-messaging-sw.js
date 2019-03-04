importScripts("https://www.gstatic.com/firebasejs/5.8.5/firebase.js");
// Initialize Firebase
var config = {
  apiKey: "AIzaSyDTPDoU-_eRDWdqrugw0AZSorKuRiQqrKk",
  authDomain: "myfitba.firebaseapp.com",
  databaseURL: "https://myfitba.firebaseio.com",
  projectId: "myfitba",
  storageBucket: "myfitba.appspot.com",
  messagingSenderId: "8662031540"
};
firebase.initializeApp(config);
var messaging = firebase.messaging();
