const menuButton = document.getElementById("menu-button")! as HTMLButtonElement;
const menuDialog = document.getElementById("menu-dialog")! as HTMLDialogElement;

menuButton.addEventListener("click", () => {
    menuDialog.showModal();
});