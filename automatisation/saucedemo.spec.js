
import { test, expect } from '@playwright/test';

/**
 * Tests de non-régression automatisés - SauceDemo
 * Les identifiants TC-xx correspondent aux cas du plan de tests (dossier plan-de-tests).
 */

const BASE_URL = 'https://www.saucedemo.com';
const PASSWORD = 'secret_sauce';

// ---------- Fonctions utilitaires ----------

async function login(page, username = 'standard_user', password = PASSWORD) {
  await page.goto(BASE_URL);
  await page.fill('#user-name', username);
  await page.fill('#password', password);
  await page.click('#login-button');
}

/** Transforme "$29.99" ou "Item total: $39.98" en nombre (29.99 / 39.98). */
function toNumber(text) {
  return parseFloat(text.replace(/[^0-9.]/g, ''));
}

// ---------- Connexion ----------

test.describe('Connexion', () => {
  test('TC-01 - Connexion valide', async ({ page }) => {
    await login(page);
    await expect(page).toHaveURL(/inventory\.html/);
    await expect(page.locator('.title')).toHaveText('Products');
  });

  test('TC-02 - Mot de passe incorrect', async ({ page }) => {
    await login(page, 'standard_user', 'mauvais_mot_de_passe');
    await expect(page.locator('[data-test="error"]')).toContainText(
      'Username and password do not match any user in this service'
    );
    await expect(page).not.toHaveURL(/inventory\.html/);
  });

  test('TC-05 - Compte bloqué', async ({ page }) => {
    await login(page, 'locked_out_user');
    await expect(page.locator('[data-test="error"]')).toContainText('locked out');
    await expect(page).not.toHaveURL(/inventory\.html/);
  });

  test('TC-06 - Accès direct sans connexion', async ({ page }) => {
    await page.goto(`${BASE_URL}/inventory.html`);
    await expect(page.locator('[data-test="error"]')).toContainText('logged in');
    await expect(page.locator('#login-button')).toBeVisible();
  });

   test('TC-19 - Déconnexion', async ({ page }) => {
    await login(page);
    await page.click('#react-burger-menu-btn');
    await expect(page.locator('#logout_sidebar_link')).toBeVisible();
    await page.click('#logout_sidebar_link');
    await expect(page.locator('#login-button')).toBeVisible();
  });
});

// ---------- Catalogue ----------

test.describe('Catalogue', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('TC-07 - Affichage de la liste des produits', async ({ page }) => {
    const items = page.locator('.inventory_item');
    await expect(items).toHaveCount(6);
    // Chaque produit a un nom, un prix et un bouton d'ajout
    await expect(page.locator('.inventory_item_name')).toHaveCount(6);
    await expect(page.locator('.inventory_item_price')).toHaveCount(6);
    await expect(page.locator('button:has-text("Add to cart")')).toHaveCount(6);
  });

  test('TC-10 - Tri par prix croissant', async ({ page }) => {
    await page.selectOption('.product_sort_container', 'lohi');
    const priceTexts = await page.locator('.inventory_item_price').allTextContents();
    const prices = priceTexts.map(toNumber);
    const sorted = [...prices].sort((a, b) => a - b);
    expect(prices).toEqual(sorted);
  });
});

// ---------- Panier ----------

test.describe('Panier', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
  });

  test('TC-12 - Ajout d\'un produit', async ({ page }) => {
    await page.click('#add-to-cart-sauce-labs-backpack');
    await expect(page.locator('.shopping_cart_badge')).toHaveText('1');
    await expect(page.locator('#remove-sauce-labs-backpack')).toBeVisible();
  });

  test('TC-13 - Ajout de plusieurs produits', async ({ page }) => {
    await page.click('#add-to-cart-sauce-labs-backpack');
    await page.click('#add-to-cart-sauce-labs-bike-light');
    await page.click('#add-to-cart-sauce-labs-bolt-t-shirt');
    await expect(page.locator('.shopping_cart_badge')).toHaveText('3');
    await page.click('.shopping_cart_link');
    await expect(page.locator('.cart_item')).toHaveCount(3);
  });

  test('TC-14 - Suppression d\'un produit', async ({ page }) => {
    await page.click('#add-to-cart-sauce-labs-backpack');
    await page.click('.shopping_cart_link');
    await page.click('#remove-sauce-labs-backpack');
    await expect(page.locator('.cart_item')).toHaveCount(0);
    await expect(page.locator('.shopping_cart_badge')).toHaveCount(0);
  });
});

// ---------- Commande ----------

test.describe('Commande', () => {
  test.beforeEach(async ({ page }) => {
    await login(page);
    await page.click('#add-to-cart-sauce-labs-backpack');
    await page.click('#add-to-cart-sauce-labs-bike-light');
    await page.click('.shopping_cart_link');
    await page.click('#checkout');
    await page.fill('#first-name', 'Arij');
    await page.fill('#last-name', 'Saadaoui');
    await page.fill('#postal-code', '1002');
    await page.click('#continue');
    await expect(page).toHaveURL(/checkout-step-two/);
  });

  test('TC-18 - Calcul du total (sous-total + taxe = total)', async ({ page }) => {
    const subtotal = toNumber(await page.locator('.summary_subtotal_label').innerText());
    const tax = toNumber(await page.locator('.summary_tax_label').innerText());
    const total = toNumber(await page.locator('.summary_total_label').innerText());

    // Le sous-total doit correspondre à la somme des prix des articles
    const itemPrices = await page.locator('.inventory_item_price').allTextContents();
    const sumItems = itemPrices.map(toNumber).reduce((a, b) => a + b, 0);

    expect(subtotal).toBeCloseTo(sumItems, 2);
    expect(total).toBeCloseTo(subtotal + tax, 2);
  });

  test('TC-15 - Commande complète (parcours nominal)', async ({ page }) => {
    await page.click('#finish');
    await expect(page.locator('.complete-header')).toHaveText('Thank you for your order!');
  });
});