import { Router } from 'express';
import { getCampuses, createCampusHandler, updateCampusHandler, deleteCampusHandler } from '../controllers/campusController.js';
import { getHalls, createHallHandler, updateHallHandler, deleteHallHandler } from '../controllers/hallController.js';
import { getMenu, likeMenuItem, rateMenuItem, createMenuItemHandler, updateMenuItemHandler, deleteMenuItemHandler, copyMenuHandler } from '../controllers/menuController.js';
import { postSuggestion } from '../controllers/suggestionController.js';
import { contact, updateContact } from '../controllers/contactController.js';
import { login, register } from '../controllers/authController.js';
import { createUserHandler, deleteUserHandler, getUsers, updateUserHandler } from '../controllers/userController.js';
import { requireAuth, requireRole } from '../middleware/auth.js';

export const router = Router();

// Auth
router.post('/auth/login', login);
router.post('/auth/register', requireAuth, requireRole(['admin']), register);

// Public data
router.get('/campuses', getCampuses);
router.get('/halls', getHalls);
router.get('/menu', getMenu);
router.post('/menu/:id/like', likeMenuItem);
router.post('/menu/:id/rating', rateMenuItem);
router.post('/suggestions', postSuggestion);
router.get('/contact', contact);

// Protected admin/manager
router.post('/campuses', requireAuth, requireRole(['admin']), createCampusHandler);
router.put('/campuses/:id', requireAuth, requireRole(['admin']), updateCampusHandler);
router.delete('/campuses/:id', requireAuth, requireRole(['admin']), deleteCampusHandler);

router.post('/halls', requireAuth, requireRole(['admin', 'manager']), createHallHandler);
router.put('/halls/:id', requireAuth, requireRole(['admin', 'manager']), updateHallHandler);
router.delete('/halls/:id', requireAuth, requireRole(['admin', 'manager']), deleteHallHandler);

router.post('/menu', requireAuth, requireRole(['admin', 'manager']), createMenuItemHandler);
router.put('/menu/:id', requireAuth, requireRole(['admin', 'manager']), updateMenuItemHandler);
router.delete('/menu/:id', requireAuth, requireRole(['admin', 'manager']), deleteMenuItemHandler);
router.post('/menu/copy', requireAuth, requireRole(['admin', 'manager']), copyMenuHandler);

router.put('/contact', requireAuth, requireRole(['admin']), updateContact);

router.get('/users', requireAuth, requireRole(['admin']), getUsers);
router.post('/users', requireAuth, requireRole(['admin']), createUserHandler);
router.put('/users/:id', requireAuth, updateUserHandler);
router.delete('/users/:id', requireAuth, requireRole(['admin']), deleteUserHandler);
