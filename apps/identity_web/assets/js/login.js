(() => {
    const form = document.currentScript.parentNode;
    const submitButton = form.querySelector('button[type="submit"]');
    form.onsubmit = function (event) {
        const currentAction = form.querySelector('input[name="user[submit_action]"]:checked');
        form.action = currentAction.dataset.formAction;
        form.method = "post";
    };
    form.onchange = function (event) {
        const currentAction = form.querySelector('input[name="user[submit_action]"]:checked');
        submitButton.innerText = currentAction.dataset.submit;
    };
})();