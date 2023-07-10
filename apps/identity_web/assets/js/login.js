(() => {
    const form = document.querySelector("form");
    const submitButton = form.querySelector('button[type="submit"]');
    form.onsubmit = function (event) {
        setSubmitAction();
    };
    form.onchange = function (event) {
        setSubmitAction();
        checkValidity();
    };
    form.oninput = function (event) {
        checkValidity();
    };
    function setSubmitAction() {
        const currentAction = form.querySelector('input[name="user[submit_action]"]:checked');
        submitButton.innerText = currentAction.dataset.submit;
        form.action = currentAction.dataset.formAction;
    }
    function checkValidity() {
        submitButton.disabled = !form.checkValidity();
    }
})();