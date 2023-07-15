(() => {
    const form = document.querySelector("form");
    const passwordFieldset = form.querySelector('fieldset.password');
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
    if (passwordFieldset) {
        const passwordLabel = passwordFieldset.querySelector('label');
        const passwordInput = passwordFieldset.querySelector('input[type="password"]');
        passwordLabel.onclick = function (event) {
            if (event.layerY > event.target.offsetHeight) {
                const shown = passwordInput.type === 'text';
                passwordInput.type = shown ? 'password' : 'text';
                passwordLabel.classList.toggle('lenra-icon-eye');
                passwordLabel.classList.toggle('lenra-icon-eye-off');
            }
        }
    }
})();